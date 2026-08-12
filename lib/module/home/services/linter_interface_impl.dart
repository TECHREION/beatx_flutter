import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/home/model/listem_miusic_detalis_model.dart';
import 'package:beatx_flutter/module/home/model/listen_model.dart';
import 'package:beatx_flutter/module/home/model/miusic_stream.dart';

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
}