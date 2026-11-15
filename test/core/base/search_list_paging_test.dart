import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/base/search_list_controller.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// A backend holding [catalogue] rows that pages like the live `/search`
/// routes do. Its text search matches whole words only.
class _Search extends SearchListController<String> {
  _Search(this.catalogue);

  final List<String> catalogue;
  final asked = <({String query, int page, int limit})>[];

  @override
  FutureRequest<Success<PagedResult<String>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    asked.add((query: query, page: page, limit: limit));
    final hits = query.isEmpty
        ? catalogue
        : catalogue.where((row) => row.split(' ').contains(query)).toList();
    final start = (page - 1) * limit;
    return Right(
      Success(
        data: PagedResult(
          items: hits.skip(start).take(limit).toList(),
          total: hits.length,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  @override
  String searchableText(String row) => row;
}

void main() {
  final catalogue = [for (var i = 0; i < 95; i++) 'song $i'];

  test('opens on one page and fetches the next only when asked', () async {
    final search = _Search(catalogue);
    await search.search();

    expect(search.results, hasLength(SearchListController.pageSize));
    expect(search.asked, [(query: '', page: 1, limit: 20)]);
    expect(search.hasMore, isTrue);

    await search.loadMore();
    expect(search.results, hasLength(40));
    expect(search.asked.last, (query: '', page: 2, limit: 20));
  });

  test('a part-typed name pulls in no more than a screenful', () async {
    final search = _Search(catalogue)..query.value = 'son';
    await search.search();

    // Backend misses, then the catalogue's first page is narrowed here —
    // which is already a full screen, so nothing more is fetched.
    expect(search.asked.map((a) => a.page), [1, 1]);
    expect(search.results, hasLength(20));
  });
}
