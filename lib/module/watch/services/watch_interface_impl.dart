import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/watch/model/get_stream_url_model.dart';
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
}