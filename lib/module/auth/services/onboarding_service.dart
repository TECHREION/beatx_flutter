import 'package:app_pigeon/app_pigeon.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/typedefs.dart';

/// An artist offered on the onboarding screen.
class OnboardingArtist {
  const OnboardingArtist({required this.id, required this.name, this.avatar});

  final String id;
  final String name;
  final String? avatar;

  /// Reads `/discovery/recommended-artists` and `/users/artists` rows, which
  /// both carry `_id`, `name`, an optional `stageName` and an avatar.
  factory OnboardingArtist.fromJson(Map<String, dynamic> json) {
    final stage = (json['stageName'] ?? '').toString().trim();
    final avatar = (json['artistAvatar'] ?? json['avatar'] ?? '')
        .toString()
        .trim();
    return OnboardingArtist(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: stage.isNotEmpty ? stage : (json['name'] ?? '').toString(),
      avatar: avatar.isEmpty ? null : avatar,
    );
  }
}

/// A genre offered on the onboarding screen.
class OnboardingGenre {
  const OnboardingGenre({required this.id, required this.name});

  final String id;
  final String name;

  factory OnboardingGenre.fromJson(Map<String, dynamic> json) =>
      OnboardingGenre(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

/// The listener onboarding calls: what to offer, and saving the picks.
///
/// Finishing or skipping both end with `PATCH /users/profile
/// {onboardingCompleted: true}`, so the flow is shown only once.
base class OnboardingService extends BaseRepository {
  OnboardingService(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  List<Map<String, dynamic>> _rows(Object? body) => pagedEntries(
    body is Map ? body['data'] : null,
  ).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();

  /// Artists to suggest, minus ones already followed (limit is capped at 30).
  FutureRequest<Success<List<OnboardingArtist>>> recommendedArtists() =>
      asyncTryCatch(
        tryFunc: () async {
          final response = await appPigeon.get(
            ApiEndpoints.recommendedArtists,
            queryParameters: {'limit': 30},
          );
          return Success(
            data: _rows(response.data)
                .map(OnboardingArtist.fromJson)
                .where((artist) => artist.id.isNotEmpty)
                .toList(),
          );
        },
      );

  /// Artists matching [query] by name.
  FutureRequest<Success<List<OnboardingArtist>>> searchArtists(String query) =>
      asyncTryCatch(
        tryFunc: () async {
          final response = await appPigeon.get(
            ApiEndpoints.searchArtists,
            queryParameters: {'q': query, 'page': 1, 'limit': 30},
          );
          return Success(
            data: _rows(response.data)
                .map(OnboardingArtist.fromJson)
                .where((artist) => artist.id.isNotEmpty)
                .toList(),
          );
        },
      );

  /// Every current genre. Ids must come from here: `PATCH /users/me/genres`
  /// refuses ids that no longer exist.
  FutureRequest<Success<List<OnboardingGenre>>> genres() => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(
        ApiEndpoints.genre,
        queryParameters: {'page': 1, 'limit': 100},
      );
      return Success(
        data: _rows(response.data)
            .map(OnboardingGenre.fromJson)
            .where((genre) => genre.id.isNotEmpty)
            .toList(),
      );
    },
  );

  /// Saves the picks and marks onboarding done. Empty lists are not sent, so
  /// skipping only records completion.
  FutureRequest<Success<NoData>> complete({
    List<String> artistIds = const [],
    List<String> genreIds = const [],
  }) => asyncTryCatch(
    tryFunc: () async {
      if (artistIds.isNotEmpty) {
        await appPigeon.patch(
          ApiEndpoints.favoriteArtists,
          data: {'artistIds': artistIds},
        );
      }
      if (genreIds.isNotEmpty) {
        await appPigeon.patch(
          ApiEndpoints.favoriteGenres,
          data: {'genreIds': genreIds},
        );
      }
      // The profile route is multipart (it also takes the avatar file).
      await appPigeon.patch(
        ApiEndpoints.updateProfile,
        data: FormData.fromMap({'onboardingCompleted': 'true'}),
      );
      return Success(data: NoData());
    },
  );
}
