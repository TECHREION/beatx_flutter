import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/podcast/model/episodes_details.dart';
import 'package:beatx_flutter/module/podcast/model/episodes_model.dart';
import 'package:beatx_flutter/module/podcast/model/get_stream_url_model.dart';
import 'package:beatx_flutter/module/podcast/model/podcast_details_model.dart';
import 'package:beatx_flutter/module/podcast/model/podcast_home_model.dart';
import 'package:beatx_flutter/module/podcast/model/podcast_like_model.dart';
import 'package:beatx_flutter/module/podcast/model/search_category_model.dart';

import '../../../core/constants/api_endpoints.dart';
import '../model/save_progress_data.dart';
import 'podcast_interface.dart';

final class PodcastInterfaceImpl extends PodcastInterface {
  PodcastInterfaceImpl(this.appPigeon);
  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<PodcastHomeData>> podcastHome() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.podcastHome);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: PodcastHomeData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<PodcastDetailsModel>> podcastDetails(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.podcastDetails(podcastId: id),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: PodcastDetailsModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<EpisodeDetailsData>> episodeDetails(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.episodeDetails(episodeId: id),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: EpisodeDetailsData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<EpisodeStreamData>> getStreamUrl(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getStreamUrl(episodeId: id),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: EpisodeStreamData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<EpisodeModel>>> podcastEpisodes(
    String id, {
    int page = 1,
    int limit = 100,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.podcastEpisodes(podcastId: id),
          // `limit` is capped at 100 by the API.
          queryParameters: {'page': page, 'limit': limit.clamp(1, 100)},
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        // The route pages its answer: `{ data: { data: [...], total, ... } }`.
        // pagedEntries also accepts a bare list.
        final data = pagedEntries(body['data'])
            .whereType<Map>()
            .map((e) => EpisodeModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: data,
        );
      },
    );
  }

  @override
  FutureRequest<Success<PagedResult<CategoryPodcast>>> searchPodcast({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.searchPodcast(
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
          data: PagedResult.fromJson(data, CategoryPodcast.fromJson),
        );
      },
    );
  }

  @override
  FutureRequest<Success<SearchCategoryData>> searchCategory(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.searchCategory(categoryId: id),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: SearchCategoryData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<SaveProgressData>> saveProgress(
    String id,
    int positionMs, {
    bool completed = false,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.saveProgress(episodeId: id),
          data: {'positionMs': positionMs, if (completed) 'completed': true},
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: SaveProgressData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<Podcast>>> getLikedPodcast() async {
    // The first hundred, for the heart checks; the liked screen pages.
    final result = await likedPodcastsPage(page: 1, limit: 100);
    return result.map((s) => Success(message: s.message, data: s.data?.items));
  }

  @override
  FutureRequest<Success<PagedResult<Podcast>>> likedPodcastsPage({
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getLikepodcast,
          queryParameters: {'page': page, 'limit': limit},
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        // A paged envelope, or a bare list.
        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : {'data': body['data']};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: PagedResult.fromJson(data, (json) {
            // Podcasts themselves, though a `{podcast, episodes}` envelope
            // is unwrapped if this backend sends one anyway.
            final podcast = json['podcast'];
            return Podcast.fromJson(
              podcast is Map ? Map<String, dynamic>.from(podcast) : json,
            );
          }),
        );
      },
    );
  }

  @override
  FutureRequest<Success<PodcastLikeModel>> likePodcast(String podcastid) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.likpodcast(podcastid: podcastid),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : body;

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: PodcastLikeModel.fromJson(data),
        );
      },
    );
  }
}
