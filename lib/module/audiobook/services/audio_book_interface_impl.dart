import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/audiobook/model/audio_book_details_model.dart';
import 'package:beatx_flutter/module/audiobook/model/audiobook_model.dart';
import 'package:beatx_flutter/module/audiobook/services/audio_book_interface.dart';

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
}
