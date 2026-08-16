import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/genre-artist/services/genre_artist_interface.dart';

import '../../../core/constants/api_endpoints.dart';
import '../model/genre_model.dart';

final class GenreArtistInterfaceImpl extends GenreArtistInterface {
  GenreArtistInterfaceImpl(this.appPigeon);
  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<List<GenreModel>>> getGenres() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.genre);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        // `data` is the list itself, but tolerate it being paged into an
        // inner `data` the way the song endpoints are.
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
                (item) => GenreModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
      },
    );
  }
}
