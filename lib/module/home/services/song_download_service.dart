import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../model/downloaded_song_model.dart';

/// Why a download did not finish, worded for the user.
class SongDownloadException implements Exception {
  const SongDownloadException(this.message, {this.cancelled = false});

  final String message;

  /// The user stopped it. Not an error worth reporting.
  final bool cancelled;

  @override
  String toString() => 'SongDownloadException($message)';
}

/// Saves songs to app-private storage and keeps the list of what is saved.
///
/// The audio is fetched straight from the same stream url the player uses —
/// there is no separate download endpoint. That url is a short-lived signed
/// link, so callers ask for a fresh one right before each download.
///
/// This does not protect the audio: anyone who obtains the stream url can
/// fetch the same file outside the app. Content protection would have to come
/// from the backend (DRM or encrypted segments), not from where Flutter
/// writes the file.
///
/// Layout, under the platform's application-support directory (private to
/// the app on Android and iOS, no storage permission needed):
///
/// ```
/// downloads/
///   index.json        metadata for every saved song
///   <songId>.<ext>    audio, named by id so titles never reach the filesystem
///   covers/<songId>.<ext>
/// ```
class SongDownloadService {
  SongDownloadService({Dio? dio, Future<Directory> Function()? baseDirectory})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              // Between bytes, not for the whole file.
              receiveTimeout: const Duration(seconds: 60),
            ),
          ),
      _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  // A plain client on purpose: the stream url is a presigned S3 link, and an
  // Authorization header on top of its signature makes S3 reject the request.
  final Dio _dio;
  final Future<Directory> Function() _baseDirectory;

  static const _folder = 'downloads';
  static const _coversFolder = 'covers';
  static const _indexFile = 'index.json';
  static const _partSuffix = '.part';

  static const _audioExtensions = {
    'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg', 'oga', 'opus', 'webm', 'mp4',
  };
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

  static const _audioContentTypes = {
    'audio/mpeg': 'mp3',
    'audio/mp3': 'mp3',
    'audio/mp4': 'm4a',
    'audio/x-m4a': 'm4a',
    'audio/m4a': 'm4a',
    'audio/aac': 'aac',
    'audio/flac': 'flac',
    'audio/x-flac': 'flac',
    'audio/wav': 'wav',
    'audio/x-wav': 'wav',
    'audio/wave': 'wav',
    'audio/ogg': 'ogg',
    'audio/opus': 'opus',
    'audio/webm': 'webm',
  };

  Directory? _root;

  /// The downloads folder, created on first use.
  Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;

    final base = await _baseDirectory();
    final dir = Directory('${base.path}/$_folder');
    await Directory('${dir.path}/$_coversFolder').create(recursive: true);
    return _root = dir;
  }

  /// Absolute path of [song]'s audio. Only valid after [root] has resolved.
  String audioPath(DownloadedSong song) => '${_root!.path}/${song.fileName}';

  /// Absolute path of [song]'s saved cover, or null when none was saved.
  String? coverPath(DownloadedSong song) => song.coverFileName.isEmpty
      ? null
      : '${_root!.path}/$_coversFolder/${song.coverFileName}';

  // ---------------------------------------------------------------- index

  /// Every saved song whose audio is still on disk.
  ///
  /// Also tidies up after an app that was killed mid-download: half-written
  /// `.part` files, and audio or covers the index does not know about, are
  /// deleted. Only call this while no download is running.
  Future<List<DownloadedSong>> loadIndex() async {
    final dir = await root();
    final songs = <DownloadedSong>[];

    try {
      final file = File('${dir.path}/$_indexFile');
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          for (final entry in decoded.whereType<Map>()) {
            final song = DownloadedSong.fromJson(
              Map<String, dynamic>.from(entry),
            );
            if (song.id.isEmpty || song.fileName.isEmpty) continue;
            // Metadata for audio that is gone is dropped here and rewritten
            // below, so the song simply reads as not downloaded.
            if (await File(audioPath(song)).exists()) songs.add(song);
          }
        }
      }
    } catch (_) {
      // A corrupt index is not worth failing the app over. Whatever audio it
      // described is swept up below and can be downloaded again.
    }

    await _removeOrphans(dir, songs);
    await saveIndex(songs);
    return songs;
  }

  /// Writes the whole index, through a temporary file so an app killed
  /// mid-write leaves the previous index intact.
  Future<void> saveIndex(List<DownloadedSong> songs) async {
    final dir = await root();
    final temp = File('${dir.path}/$_indexFile.tmp');
    await temp.writeAsString(
      jsonEncode(songs.map((song) => song.toJson()).toList()),
      flush: true,
    );
    await temp.rename('${dir.path}/$_indexFile');
  }

  Future<void> _removeOrphans(Directory dir, List<DownloadedSong> kept) async {
    final keepAudio = {for (final song in kept) song.fileName};
    final keepCovers = {for (final song in kept) song.coverFileName};

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name == _indexFile) continue;
      if (!keepAudio.contains(name)) await _deleteQuietly(entity);
    }

    final covers = Directory('${dir.path}/$_coversFolder');
    await for (final entity in covers.list()) {
      if (entity is! File) continue;
      if (!keepCovers.contains(entity.uri.pathSegments.last)) {
        await _deleteQuietly(entity);
      }
    }
  }

  // ------------------------------------------------------------- download

  /// Downloads [url] as [songId]'s audio and returns the saved file's name
  /// and size.
  ///
  /// [onProgress] gets a fraction from 0 to 1, or null while the server has
  /// not said how large the file is. Throws [SongDownloadException].
  Future<({String fileName, int fileSize})> downloadAudio({
    required String songId,
    required String url,
    String? fallbackExtension,
    required void Function(double? progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const SongDownloadException(
        'This song has no valid audio link to download.',
      );
    }

    final dir = await root();
    final part = File('${dir.path}/$songId$_partSuffix');
    await _deleteQuietly(part);

    final Response<dynamic> response;
    try {
      response = await _dio.download(
        url,
        part.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) =>
            onProgress(progressOf(received, total)),
      );
    } on DioException catch (error) {
      await _deleteQuietly(part);
      throw describeDioError(error);
    } on FileSystemException catch (error) {
      await _deleteQuietly(part);
      throw describeFileError(error);
    }

    try {
      final size = await part.length();
      final expected = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      // An empty body, or fewer bytes than announced, is a broken file that
      // would only fail later in the player.
      if (size == 0 || (expected != null && expected > 0 && size != expected)) {
        await _deleteQuietly(part);
        throw const SongDownloadException(
          'The download was interrupted. Tap Retry to try again.',
        );
      }

      final extension = audioExtension(
        url: url,
        contentType: response.headers.value(Headers.contentTypeHeader),
        fallback: fallbackExtension,
      );
      final fileName = '$songId.$extension';

      // A copy saved earlier under another extension would otherwise be left
      // behind unreferenced.
      await _deleteAudioFor(dir, songId);
      await part.rename('${dir.path}/$fileName');
      return (fileName: fileName, fileSize: size);
    } on FileSystemException catch (error) {
      await _deleteQuietly(part);
      throw describeFileError(error);
    }
  }

  /// Saves the cover for offline display. Best effort: returns the saved
  /// file's name, or empty when it could not be saved — the audio is what
  /// matters.
  Future<String> downloadCover({
    required String songId,
    required String url,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return '';
    }

    final dir = await root();
    final extension = _extensionFromPath(uri.path, _imageExtensions) ?? 'jpg';
    final fileName = '$songId.$extension';
    final target = File('${dir.path}/$_coversFolder/$fileName');

    try {
      await _dio.download(url, target.path, cancelToken: cancelToken);
      return await target.length() > 0 ? fileName : '';
    } catch (_) {
      await _deleteQuietly(target);
      return '';
    }
  }

  /// Deletes [song]'s audio and cover. Missing files are not an error.
  Future<void> delete(DownloadedSong song) async {
    await root();
    await _deleteQuietly(File(audioPath(song)));
    final cover = coverPath(song);
    if (cover != null) await _deleteQuietly(File(cover));
  }

  Future<void> _deleteAudioFor(Directory dir, String songId) async {
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('$songId.') && !name.endsWith(_partSuffix)) {
        await _deleteQuietly(entity);
      }
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nothing useful to do; the orphan sweep on next launch retries it.
    }
  }

  // --------------------------------------------------------------- helpers

  /// [received] out of [total], or null when [total] is unknown — a server
  /// that streams without a length reports -1, and dividing by that would
  /// show nonsense.
  static double? progressOf(int received, int total) {
    if (total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }

  /// The extension to save audio under: the one on the url's path when it
  /// is a known audio type, then the response's content type, then
  /// [fallback], then mp3.
  ///
  /// The url comes first because the backend's `streamType` is not reliable
  /// — it reports "mp3" for files that are FLAC — and the players on both
  /// platforms pick a decoder from a local file's extension.
  static String audioExtension({
    required String url,
    String? contentType,
    String? fallback,
  }) {
    final fromPath = _extensionFromPath(
      Uri.tryParse(url)?.path ?? '',
      _audioExtensions,
    );
    if (fromPath != null) return fromPath;

    final type = contentType?.split(';').first.trim().toLowerCase();
    final fromType = _audioContentTypes[type];
    if (fromType != null) return fromType;

    final normalized = fallback?.trim().toLowerCase();
    if (normalized != null && _audioExtensions.contains(normalized)) {
      return normalized;
    }
    return 'mp3';
  }

  static String? _extensionFromPath(String path, Set<String> allowed) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    return allowed.contains(extension) ? extension : null;
  }

  static SongDownloadException describeDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return const SongDownloadException(
          'Download cancelled.',
          cancelled: true,
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const SongDownloadException(
          'The download timed out. Check your connection and tap Retry.',
        );
      case DioExceptionType.connectionError:
        return const SongDownloadException(
          'No internet connection. Connect and tap Retry.',
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401 || status == 403) {
          return const SongDownloadException(
            'The download link expired. Tap Retry to get a new one.',
          );
        }
        if (status == 404) {
          return const SongDownloadException(
            "This song's audio could not be found.",
          );
        }
        if (status >= 500) {
          return const SongDownloadException(
            'The server is unavailable right now. Try again later.',
          );
        }
        return SongDownloadException('Download failed (HTTP $status).');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause is FileSystemException) return describeFileError(cause);
        if (cause is SocketException) {
          return const SongDownloadException(
            'No internet connection. Connect and tap Retry.',
          );
        }
        return const SongDownloadException('Download failed. Tap Retry.');
    }
  }

  static SongDownloadException describeFileError(FileSystemException error) {
    // ENOSPC is 28 on both Android (Linux) and iOS (Darwin).
    if (error.osError?.errorCode == 28) {
      return const SongDownloadException(
        'Not enough storage space to download this song.',
      );
    }
    return const SongDownloadException(
      'The song could not be saved on this device.',
    );
  }
}
