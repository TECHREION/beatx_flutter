import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/podcast/model/episodes_details.dart';
import 'package:beatx_flutter/module/podcast/model/episodes_model.dart';
import 'package:beatx_flutter/module/podcast/model/get_stream_url_model.dart';
import 'package:beatx_flutter/module/podcast/model/podcast_details_model.dart';
import 'package:beatx_flutter/module/podcast/model/podcast_home_model.dart';
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
  FutureRequest<Success<List<EpisodeModel>>> podcastEpisodes(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.podcastEpisodes(podcastId: id),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is List
            ? (body['data'] as List)
                  .map((e) => EpisodeModel.fromJson(e))
                  .toList()
            : <EpisodeModel>[];

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: data,
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
    int positionMs,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.saveProgress(episodeId: id),
          data: {'positionMs': positionMs},
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
}
