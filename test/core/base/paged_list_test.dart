import 'dart:async';

import 'package:beatx_flutter/core/api_handler/failure.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/base/paged_list.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server holding [count] items, answering pages of them.
class _Server {
  _Server(this.count, {this.reportTotal = true});

  int count;
  final bool reportTotal;
  final asked = <int>[];
  bool fail = false;

  Future<Request<Success<PagedResult<String>>>> page(
    int page,
    int limit,
  ) async {
    asked.add(page);
    if (fail) {
      return Left(
        DataCRUDFailure(failure: Failure.socketFailure, fullError: 'offline'),
      );
    }
    final start = (page - 1) * limit;
    final items = [
      for (var i = start; i < start + limit && i < count; i++) 'item$i',
    ];
    return Right(
      Success(
        data: PagedResult(
          items: items,
          total: reportTotal ? count : 0,
          page: page,
          limit: limit,
        ),
      ),
    );
  }
}

void main() {
  test('loads a page at a time until the total is reached', () async {
    final server = _Server(45);
    final list = PagedList<String>(fetch: server.page, idOf: (s) => s);

    await list.refresh();
    expect(list.items.length, 20);
    expect(list.total.value, 45);
    expect(list.hasMore, isTrue);

    await list.loadMore();
    await list.loadMore();
    expect(list.items.length, 45);
    expect(list.hasMore, isFalse);

    // Nothing past the end is asked for.
    await list.loadMore();
    expect(server.asked, [1, 2, 3]);
  });

  test('a route with no total is paged while pages come back full', () async {
    final server = _Server(30, reportTotal: false);
    final list = PagedList<String>(fetch: server.page);

    await list.refresh();
    expect(list.hasMore, isTrue);
    await list.loadMore();
    expect(list.items.length, 30);
    expect(list.hasMore, isFalse);
  });

  test('a second load while one runs is not sent twice', () async {
    final gate = Completer<void>();
    final server = _Server(60);
    final list = PagedList<String>(
      fetch: (page, limit) async {
        if (page == 2) await gate.future;
        return server.page(page, limit);
      },
    );
    await list.refresh();

    final first = list.loadMore();
    final second = list.loadMore();
    gate.complete();
    await Future.wait([first, second]);

    expect(server.asked, [1, 2]);
    expect(list.items.length, 40);
  });

  test('a page that lands after a refresh is dropped', () async {
    final gate = Completer<void>();
    final server = _Server(60);
    final list = PagedList<String>(
      fetch: (page, limit) async {
        if (page == 2) await gate.future;
        return server.page(page, limit);
      },
    );
    await list.refresh();

    final stale = list.loadMore();
    await list.refresh();
    gate.complete();
    await stale;

    // Only the refreshed first page: the old page 2 did not land on it.
    expect(list.items.length, 20);
  });

  test('removing an item keeps the total in step', () async {
    final list = PagedList<String>(fetch: _Server(45).page);
    await list.refresh();

    list.remove((s) => s == 'item3');
    expect(list.items.length, 19);
    expect(list.total.value, 44);
  });

  test('a failed page keeps what was loaded and says why', () async {
    final server = _Server(45);
    final list = PagedList<String>(fetch: server.page);
    await list.refresh();

    server.fail = true;
    await list.loadMore();
    expect(list.items.length, 20);
    expect(list.errorMessage.value, isNotEmpty);
    expect(list.isLoadingMore.value, isFalse);
  });
}
