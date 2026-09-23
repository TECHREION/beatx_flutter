/// Pulls the entry list out of a paged envelope's `data` object.
///
/// The songs routes answer `{ "data": { "songs": [...], "total", "page",
/// "limit" } }`, while others use `items` or nest the list under `data` again,
/// and a couple answer with the bare list. Reading whichever is present keeps
/// one endpoint's choice of key from silently emptying a screen: a missing key
/// yields no entries and no error, which looks exactly like "the user has
/// nothing here".
List<dynamic> pagedEntries(Object? json) {
  if (json is List) return json;
  if (json is! Map) return const [];
  for (final key in const ['songs', 'items', 'data']) {
    final value = json[key];
    if (value is List) return value;
  }
  return const [];
}

/// One page of a list endpoint that answers `{ data: [...], total, page,
/// limit }` — the shape every `/search` route uses.
class PagedResult<T> {
  const PagedResult({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<T> items;

  /// How many entries match in total, across every page.
  final int total;
  final int page;
  final int limit;

  /// Reads a page out of [json], mapping each entry with [fromItem].
  ///
  /// Pass the envelope's `data` object; [pagedEntries] finds the list inside
  /// it whichever key it arrived under.
  static PagedResult<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final entries = pagedEntries(json);

    final items = entries
        .whereType<Map>()
        .map((item) => fromItem(Map<String, dynamic>.from(item)))
        .toList();

    return PagedResult<T>(
      items: items,
      // Falls back to what came back, so a response that carries no counter
      // still reports the entries it holds rather than none.
      total: _asInt(json['total'], fallback: items.length),
      page: _asInt(json['page'], fallback: 1),
      limit: _asInt(json['limit'], fallback: 20),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
