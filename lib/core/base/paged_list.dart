import 'dart:async';

import 'package:get/get.dart';

import '../api_handler/paged_result.dart';
import '../api_handler/success.dart';
import '../helpers/typedefs.dart';

/// Fetches one page of a list: [page] counts from 1.
typedef PageFetcher<T> =
    FutureRequest<Success<PagedResult<T>>> Function(int page, int limit);

/// A list that loads a page at a time, so a long one (hundreds of liked
/// songs, every episode of a show) never arrives — or sits in memory, or is
/// laid out — all at once.
///
/// [refresh] loads the first page, replacing what is there; [loadMore]
/// appends the next one, and does nothing while a load is running or once
/// [total] has been reached. A response for a list that has since been
/// refreshed is dropped.
class PagedList<T> {
  PagedList({required this.fetch, this.pageSize = 20, this.idOf});

  final PageFetcher<T> fetch;
  final int pageSize;

  /// Identifies an item, so one that moved onto the next page between two
  /// requests (a like added at the top) is not listed twice.
  final String Function(T item)? idOf;

  final items = <T>[].obs;

  /// How many there are on the server, across every page.
  final total = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  /// False until the first page has come back, so an empty list can be told
  /// apart from one that has not loaded yet.
  final hasLoaded = false.obs;

  int _page = 0;

  /// Bumped by [refresh], so a page still in flight for the old list is
  /// ignored when it lands.
  int _generation = 0;
  Future<void>? _refreshing;

  bool get hasMore => hasLoaded.value && items.length < total.value;

  /// Loads the first page again. A second call while one is running joins it.
  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final generation = ++_generation;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await fetch(1, pageSize);
    if (generation != _generation) return;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final page = success.data ?? PagedResult<T>();
      _page = 1;
      items.assignAll(page.items);
      total.value = _totalOf(page, items.length);
    });
    hasLoaded.value = true;
    isLoading.value = false;
    isLoadingMore.value = false;
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final result = await fetch(_page + 1, pageSize);
    if (generation != _generation) return;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final page = success.data ?? PagedResult<T>();
      _page++;
      final key = idOf;
      final seen = key == null ? null : {for (final i in items) key(i)};
      final fresh = seen == null
          ? page.items
          : page.items.where((i) => !seen.contains(key!(i))).toList();
      items.addAll(fresh);
      // An empty page means the server has nothing past here, whatever its
      // count said; stop asking.
      total.value = page.items.isEmpty
          ? items.length
          : _totalOf(page, items.length);
    });
    isLoadingMore.value = false;
  }

  /// Takes [item] off the list (an unlike), keeping the count in step.
  void remove(bool Function(T item) test) {
    final before = items.length;
    items.removeWhere(test);
    total.value = (total.value - (before - items.length)).clamp(0, 1 << 30);
  }

  /// The server's count, but never less than what is already listed — a
  /// route that reports no total gets one more page asked of it only while
  /// pages keep coming back full.
  int _totalOf(PagedResult<T> page, int listed) {
    if (page.total > listed) return page.total;
    return page.items.length >= pageSize ? listed + 1 : listed;
  }
}
