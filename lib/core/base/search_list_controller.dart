import 'dart:async';

import 'package:get/get.dart';

import '../api_handler/paged_result.dart';
import '../api_handler/success.dart';
import '../helpers/typedefs.dart';

/// What the song, video and audiobook search screens all do: hold a query and
/// a genre filter, ask the backend for page one whenever either changes, and
/// page in more as the list is scrolled.
///
/// Subclasses only supply [fetchPage] — the endpoints differ, the behaviour
/// around them does not.
abstract class SearchListController<T> extends GetxController {
  /// Results per request — the backend's own default.
  static const pageSize = 20;

  /// How long typing settles before a request goes out. Long enough that a
  /// word is not one request per letter, short enough to feel live.
  static const _typingPause = Duration(milliseconds: 400);

  /// What the user typed.
  final query = ''.obs;

  /// The genre filter, or empty for every genre.
  final genreId = ''.obs;

  final results = <T>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  /// How many entries match on the backend, which is what says whether there
  /// is another page to ask for.
  final total = 0.obs;

  /// False until the first answer lands, so an empty list can be told apart
  /// from one that has not been asked for yet.
  final hasSearched = false.obs;

  Timer? _typingTimer;
  int _page = 1;

  /// Entries received so far, matching or not. Paging is counted in what the
  /// backend sent rather than in what survived [_matches], which is what is
  /// left of it once a part-typed name has been filtered here.
  int _fetched = 0;

  /// Whether the rows on screen were narrowed here rather than by the
  /// backend. See [search] for when that happens.
  bool _filteredLocally = false;

  /// Below this, a part-typed name is too broad to filter on here — one or
  /// two letters would match most of the library.
  static const _minLocalQuery = 2;

  /// A part-typed name can leave a page with only a match or two on it, which
  /// is too short to scroll and so would never ask for the next page. Up to
  /// this many extra pages are pulled in to fill the first screen.
  static const _maxAutoPages = 4;

  // Bumped by every search, so an answer to a query the user has already
  // typed past cannot overwrite the newer one.
  int _requestId = 0;

  /// Whether the backend holds entries past the ones already fetched.
  bool get hasMore => _fetched < total.value;

  /// One page of matches. `query` and `genreId` are empty when unset, and the
  /// implementation is expected to leave the matching parameter off the
  /// request rather than send a blank one.
  FutureRequest<Success<PagedResult<T>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });

  /// The names a row is found by — its title, and whoever it is by.
  ///
  /// Used to match a name the backend's own search cannot: `GET /*/search`
  /// matches whole words, so "Mahi" finds nothing for "Mahiya".
  String searchableText(T item);

  bool _matches(T item, String query) =>
      searchableText(item).toLowerCase().contains(query.toLowerCase());

  @override
  void onInit() {
    super.onInit();
    // Opens on everything rather than an empty screen — the search then
    // narrows what is already there.
    search();
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    super.onClose();
  }

  /// Call from the search field. Runs the search once typing settles.
  void onQueryChanged(String value) {
    query.value = value;

    _typingTimer?.cancel();
    _typingTimer = Timer(_typingPause, search);
  }

  /// Call from the genre chips. [id] is empty for "All".
  void selectGenre(String id) {
    if (genreId.value == id) return;

    genreId.value = id;
    search();
  }

  void clearQuery() {
    if (query.value.isEmpty) return;

    query.value = '';
    search();
  }

  /// Runs the search from the first page, replacing what is on screen.
  ///
  /// The name goes to the backend first, which matches whole words against
  /// its own index — that is the better search, and it reaches the entries
  /// this screen has not fetched. A name still being typed matches nothing
  /// there, though, so an empty answer to one is re-run without the name and
  /// narrowed here instead, against what a row actually shows.
  Future<void> search() async {
    _typingTimer?.cancel();

    final request = ++_requestId;
    final typed = query.value.trim();

    isLoading.value = true;
    errorMessage.value = '';

    var fetch = await _fetch(query: typed, page: 1);

    // A newer search has taken over — its answer is the one that counts, and
    // it will clear the flags.
    if (request != _requestId) return;

    var locally = false;
    if (fetch.page?.items.isEmpty == true && typed.length >= _minLocalQuery) {
      final fallback = await _fetch(query: '', page: 1);
      if (request != _requestId) return;

      if (fallback.page != null) {
        fetch = fallback;
        locally = true;
      }
    }

    final page = fetch.page;
    if (page == null) {
      errorMessage.value = fetch.error;
      results.clear();
      total.value = 0;
      _fetched = 0;
    } else {
      _page = 1;
      _filteredLocally = locally;
      _fetched = page.items.length;
      total.value = page.total;
      results.assignAll(_keep(page.items, typed));
    }

    hasSearched.value = true;
    isLoading.value = false;

    if (locally) await _fillFirstScreen(request);
  }

  /// Appends the next page. Does nothing once everything has been fetched.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;

    final request = _requestId;
    final typed = query.value.trim();
    isLoadingMore.value = true;

    // In local mode the name is not what the backend is paging by, so it is
    // left off here too and applied to the answer instead.
    final fetch = await _fetch(
      query: _filteredLocally ? '' : typed,
      page: _page + 1,
    );

    // The query or the genre moved on while this page was in flight, so these
    // entries belong to a search nobody is looking at any more.
    if (request != _requestId) {
      isLoadingMore.value = false;
      return;
    }

    final page = fetch.page;
    if (page == null) {
      errorMessage.value = fetch.error;
    } else {
      _page += 1;
      _fetched += page.items.length;
      total.value = page.total;
      results.addAll(_keep(page.items, typed));
    }

    isLoadingMore.value = false;
  }

  /// A page filtered locally can come back with a match or two on it, which
  /// leaves the list too short to scroll — and so too short to ask for the
  /// next page. This pulls in a few more to fill the screen.
  Future<void> _fillFirstScreen(int request) async {
    var pages = 0;

    while (request == _requestId &&
        hasMore &&
        results.length < pageSize &&
        pages < _maxAutoPages) {
      pages++;
      await loadMore();
    }
  }

  /// [items] narrowed to those matching [typed], or all of them when the
  /// backend has already done the narrowing.
  Iterable<T> _keep(List<T> items, String typed) {
    if (!_filteredLocally || typed.isEmpty) return items;
    return items.where((item) => _matches(item, typed));
  }

  Future<_FetchedPage<T>> _fetch({
    required String query,
    required int page,
  }) async {
    final result = await fetchPage(
      query: query,
      genreId: genreId.value,
      page: page,
      limit: pageSize,
    );

    return result.fold(
      (failure) => _FetchedPage<T>(error: failure.uiMessage),
      (success) => _FetchedPage<T>(page: success.data ?? PagedResult<T>()),
    );
  }
}

/// One answer from [SearchListController.fetchPage]: the page, or why there
/// isn't one.
class _FetchedPage<T> {
  const _FetchedPage({this.page, this.error = ''});

  final PagedResult<T>? page;
  final String error;
}
