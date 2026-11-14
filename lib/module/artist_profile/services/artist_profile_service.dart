import 'package:app_pigeon/app_pigeon.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/artist_profile_model.dart';

/// The public artist page.
///
/// `GET /artists/:id` gives the profile (404 for non-artists and private
/// profiles); the lists come from the content routes filtered by `ownerId`.
/// A failed list only leaves that section empty — the page still opens.
base class ArtistProfileService extends BaseRepository {
  ArtistProfileService(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  Future<List<Map<String, dynamic>>> _list(
    String url,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await appPigeon.get(url, queryParameters: query);
      final body = response.data;
      return pagedEntries(
        body is Map ? body['data'] : null,
      ).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (_) {
      return const [];
    }
  }

  FutureRequest<Success<ArtistProfileModel>> load(String artistId) =>
      asyncTryCatch(
        tryFunc: () async {
          final profileRequest = appPigeon.get(
            ApiEndpoints.artistProfile(artistId: artistId),
          );
          final lists = await Future.wait([
            _list(ApiEndpoints.songs, {
              'ownerId': artistId,
              'sort': 'plays',
              'limit': 5,
            }),
            _list(ApiEndpoints.albums, {'ownerId': artistId, 'limit': 10}),
            _list(ApiEndpoints.events, {
              'ownerId': artistId,
              'upcoming': true,
              'limit': 5,
            }),
            _list(ApiEndpoints.relatedArtists(artistId: artistId), {'limit': 10}),
            _list(ApiEndpoints.products, {'ownerId': artistId, 'limit': 20}),
          ]);

          final response = await profileRequest;
          final data = response.data is Map ? response.data['data'] : null;
          final songs = lists[0];

          return Success(
            data: ArtistProfileModel.fromJson(
              data is Map ? Map<String, dynamic>.from(data) : const {},
              songs: [
                for (var i = 0; i < songs.length; i++)
                  ArtistSongModel.fromJson(songs[i], i),
              ],
              albums: lists[1].map(AlbumModel.fromJson).toList(),
              tourDates: lists[2].map(TourDateModel.fromJson).toList(),
              similarArtists: lists[3]
                  .map(SimilarArtistModel.fromJson)
                  .where((a) => a.id.isNotEmpty)
                  .toList(),
              products: lists[4].map(ArtistProductModel.fromJson).toList(),
            ),
          );
        },
      );

  /// `POST /users/:id/follow` toggles; answers `{following, followerCount}`.
  FutureRequest<Success<(bool, int)>> toggleFollow(String artistId) =>
      asyncTryCatch(
        tryFunc: () async {
          final response = await appPigeon.post(
            ApiEndpoints.followUser(userId: artistId),
          );
          final data = response.data is Map ? response.data['data'] : null;
          final map = data is Map ? data : const {};
          final count = map['followerCount'];
          return Success(
            data: (map['following'] == true, count is num ? count.toInt() : 0),
          );
        },
      );
}
