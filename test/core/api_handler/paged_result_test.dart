import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/module/podcast/model/search_category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pagedEntries reads the list under the key each route uses', () {
    for (final key in [
      'songs',
      'videos',
      'podcasts',
      'audiobooks',
      'albums',
      'items',
      'data',
    ]) {
      test(key, () {
        expect(
          pagedEntries({
            key: [1, 2],
            'total': 2,
          }),
          [1, 2],
        );
      });
    }

    test('a bare list', () => expect(pagedEntries([1]), [1]));
    test('nothing usable', () => expect(pagedEntries('x'), isEmpty));
  });

  test('a search page keeps its entries and counters', () {
    final page = PagedResult.fromJson<String>({
      'videos': [
        {'_id': 'a'},
      ],
      'total': 9,
      'page': 2,
      'limit': 1,
    }, (item) => item['_id'] as String);

    expect(page.items, ['a']);
    expect(page.total, 9);
    expect(page.page, 2);
  });

  test('the podcast category page reads the podcasts key', () {
    final page = SearchCategoryData.fromJson({
      'podcasts': [
        {'_id': 'p1', 'title': 'Show'},
      ],
      'total': 1,
      'page': 1,
      'limit': 20,
    });

    expect(page.data.single.title, 'Show');
  });
}
