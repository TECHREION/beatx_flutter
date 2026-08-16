/// Query string for the `/search` routes, which all take the same four
/// parameters: `q`, `genre` (a genre id), `page` and `limit`.
///
/// An unset filter is left out rather than sent blank — the backend rejects
/// parameters it does not know and matches on nothing when one is empty, so
/// "no filter" has to mean "not sent".
Map<String, dynamic> searchQueryParameters({
  required String query,
  required String genreId,
  required int page,
  required int limit,
}) {
  return {
    if (query.isNotEmpty) 'q': query,
    if (genreId.isNotEmpty) 'genre': genreId,
    'page': page,
    'limit': limit,
  };
}
