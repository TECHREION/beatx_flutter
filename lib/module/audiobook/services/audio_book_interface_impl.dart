import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/helpers/search_query.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/audiobook/model/audio_book_details_model.dart';
import 'package:beatx_flutter/module/audiobook/model/audiobook_model.dart';
import 'package:beatx_flutter/module/audiobook/services/audio_book_interface.dart';

import '../model/audio_book_like_model.dart';
import '../model/audio_book_stream_url_model.dart';

final class AudioBookInterfaceImpl extends AudioBookInterface {
  AudioBookInterfaceImpl(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<HomeAudiobookData>> audiobookHome() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.audiobookhome);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: HomeAudiobookData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<AudiobookDetailsData>> audiobookDetails(
    String audiobookId,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.audiobookDetails(audiobookId: audiobookId),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: AudiobookDetailsData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<AudioBookStreamUrlModel>> audiobookStreamUrl(
    String audiobookId,
    String chapterId,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.audiobookStreamUrl(
            audiobookId: audiobookId,
            chapterId: chapterId,
          ),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: AudioBookStreamUrlModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<Audiobook>>> getLikedAudiobooks() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getLikedAudiobooks,
          queryParameters: {'page': 1, 'limit': 100},
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'];
        final items = pagedEntries(data);

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: items.whereType<Map>().map((item) {
            final entry = Map<String, dynamic>.from(item);

            // Liked books come back as books, but the details endpoint wraps
            // one in `book` — take whichever this entry carries.
            final book = entry['book'] is Map
                ? Map<String, dynamic>.from(entry['book'] as Map)
                : entry;

            return Audiobook.fromJson(book);
          }).toList(),
        );
      },
    );
  }

  @override
  FutureRequest<Success<AudioBookLikeModel>> likeAudiobook(
    String audiobookId,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.likaudiobook(audiobookId: audiobookId),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        // Toggle endpoints often answer with the new state at the top level
        // rather than wrapped in `data`, so fall back to the body itself.
        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : body;

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: AudioBookLikeModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<PagedResult<Audiobook>>> searchAudiobook({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.searchAudiobook,
          queryParameters: searchQueryParameters(
            query: query,
            genreId: genreId,
            page: page,
            limit: limit,
          ),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            // A response that answers with the list alone still has to reach
            // the same parser, which reads the entries off `data`.
            : {'data': body['data']};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: PagedResult.fromJson(data, Audiobook.fromJson),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<Audiobook>>> relatedAudiobooks(
    String audiobookId, {
    int limit = 10,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.relatedAudiobooks(audiobookId: audiobookId),
          queryParameters: {'limit': limit},
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          // A plain array per Swagger; read a paged body the same way.
          data: pagedEntries(body['data'])
              .whereType<Map>()
              .map((e) => Audiobook.fromJson(Map<String, dynamic>.from(e)))
              .where((book) => book.id.isNotEmpty && book.id != audiobookId)
              .toList(),
        );
      },
    );
  }
}
