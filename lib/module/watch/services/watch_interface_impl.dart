import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/search_query.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/watch/model/get_stream_url_model.dart';
import 'package:beatx_flutter/module/watch/model/like_unlike_model.dart';
import 'package:beatx_flutter/module/watch/model/watch_model.dart';

import '../../../core/constants/api_endpoints.dart';
import '../model/video_details_model.dart';
import 'watch_interface.dart';

final class VideoInterfaceImpl extends VideoInterface {
  VideoInterfaceImpl(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<HomeData>> videoHome() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.videoHome);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: HomeData.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<VideoDetailsModel>> videoDetails(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.get(ApiEndpoints.videoDetails(videoId: id));

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: VideoDetailsModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<VideoStreamUrlModel>> getStreamUrl(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.get(ApiEndpoints.videoStreamUrl(videoId: id));

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: VideoStreamUrlModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<List<VideoModel>>> relatedVideos(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.get(ApiEndpoints.relatedVideos(videoId: id), queryParameters: {'limit': 10, 'page': 1});

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is List
            ? List<Map<String, dynamic>>.from(
                (body['data'] as List).map((e) => Map<String, dynamic>.from(e)))
            : <Map<String, dynamic>>[];

        final videos = data.map((videoJson) => VideoModel.fromJson(videoJson)).toList();

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: videos,
        );
      },
    );
  }

  @override
  FutureRequest<Success<LikeUnlikeModel>> likeUnlike(String id) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response =
            await appPigeon.post(ApiEndpoints.likeUnlike(videoId: id));

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: LikeUnlikeModel.fromJson(data),
        );
      },
    );
  }

  @override
  FutureRequest<Success<PagedResult<VideoModel>>> searchVideo({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.searchVideo,
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
          data: PagedResult.fromJson(data, VideoModel.fromJson),
        );
      },
    );
  }
}