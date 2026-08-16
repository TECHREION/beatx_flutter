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
  /// Pass the envelope's `data` object. A response that answers with the list
  /// alone is tolerated too, so long as the caller hands it over as
  /// `{'data': theList}`.
  static PagedResult<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final raw = json['data'];
    final entries = raw is List ? raw : const [];

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
