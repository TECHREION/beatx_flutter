import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/genre_model.dart';

abstract base class GenreArtistInterface extends BaseRepository {
  FutureRequest<Success<List<GenreModel>>> getGenres();
}
