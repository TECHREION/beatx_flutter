import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/search_query.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/home/model/listem_miusic_detalis_model.dart';
import 'package:beatx_flutter/module/home/model/listen_model.dart';
import 'package:beatx_flutter/module/home/model/miusic_stream.dart';
import 'package:beatx_flutter/module/home/model/on_repeat_model.dart';
import 'package:beatx_flutter/module/home/model/recently_played_model.dart';
import 'package:beatx_flutter/module/home/model/song_like_model.dart';

import '../../../core/constants/api_endpoints.dart';
import 'listen_interface.dart';

final class ListenInterfaceImpl extends ListenInterface {
  ListenInterfaceImpl(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<ListenMusicModel>> getListen() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.listenHome);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: ListenMusicModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<ListenMusicDetailsModel>> getListenDetails(String listenId) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.get(ApiEndpoints.listenDetails(listenId: listenId));

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: ListenMusicDetailsModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<SongStreamUrlModel>> getListenStreamUrl(String listenId) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.get(ApiEndpoints.listenStreamUrl(listenId: listenId));

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: SongStreamUrlModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<ListenMusicDetailsModel>>> getLikedSong() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getLikesong);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'];
        final items = data is List
            ? data
            : data is Map && data['data'] is List
                ? data['data'] as List
                : const [];

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: items
              .whereType<Map>()
              .map(
                (item) => ListenMusicDetailsModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  @override
  FutureRequest<Success<SongLikeModel>> likesong(String songId) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(ApiEndpoints.likesong(songId: songId));

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
          data: SongLikeModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<RecentlyPlayedPage>> recentlyPlayed(
    String userId, {
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.recentlyPlayed(userId: userId),
          queryParameters: {'page': page, 'limit': limit},
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
          data: RecentlyPlayedPage.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<OnRepeatPage>> onRepeatedSong({
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.onRepeatedSong,
          queryParameters: {'page': page, 'limit': limit},
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
          data: OnRepeatPage.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> searchSong({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.searchSong,
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
          data: PagedResult.fromJson(data, ListenMusicDetailsModel.fromJson),
        );
      },
    );
  }
}