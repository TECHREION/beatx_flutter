import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/core/player/now_playing.dart';
import 'package:beatx_flutter/core/player/progress_store.dart';
import 'package:beatx_flutter/module/audiobook/controller/audio_book_details_controller.dart';
import 'package:beatx_flutter/module/audiobook/model/audio_book_details_model.dart';
import 'package:beatx_flutter/module/audiobook/model/audiobook_model.dart';
import 'package:beatx_flutter/module/audiobook/services/audio_book_interface.dart';
import 'package:beatx_flutter/module/audiobook/controller/liked_audiobooks_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:beatx_flutter/core/api_handler/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `GET /audiobooks/:id`, as the test server answers for Hamlet.
const _hamlet = <String, dynamic>{
  'book': {
    '_id': 'b1',
    'title': 'Hamlet',
    'author': 'William Shakespeare',
    'universe': <Object>[],
    'totalChapters': 1,
    'totalDurationMs': 12611030,
    'genre': {'_id': 'g1', 'name': 'drama'},
  },
  'chapters': {
    'data': [
      {
        '_id': 'c1',
        'chapterNumber': 1,
        'title': 'Hamlet (Full)',
        'durationMs': 12611030,
      },
    ],
    'total': 1,
    'page': 1,
    'limit': 20,
  },
  'userProgress': null,
};

final class _FakeBooks extends AudioBookInterface {
  final answers = <Request<Success<AudiobookDetailsData>>>[];
  int calls = 0;

  @override
  FutureRequest<Success<AudiobookDetailsData>> audiobookDetails(
    String audiobookId,
  ) async {
    calls++;
    return answers.removeAt(0);
  }

  @override
  FutureRequest<Success<List<Audiobook>>> getLikedAudiobooks() async =>
      Right(Success(data: const []));

  @override
  FutureRequest<Success<List<Audiobook>>> relatedAudiobooks(
    String audiobookId, {
    int limit = 10,
  }) async => Right(Success(data: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AudiobookDetailsData', () {
    test('reads chapters from the paged shape the server sends', () {
      final details = AudiobookDetailsData.fromJson(_hamlet);
      expect(details.book?.title, 'Hamlet');
      expect(details.chapters?.single.id, 'c1');
      expect(details.chapters?.single.title, 'Hamlet (Full)');
    });

    test('reads chapters from the plain array Swagger documents', () {
      final details = AudiobookDetailsData.fromJson(const {
        'chapters': [
          {'_id': 'c1'},
        ],
      });
      expect(details.chapters?.single.id, 'c1');
    });

    test('a book with no chapters has an empty list', () {
      expect(AudiobookDetailsData.fromJson(const {}).chapters, isEmpty);
    });
  });

  group('continue listening', () {
    test('reads the nested book and progress', () {
      final book = ContinueListeningBook.fromJson(const {
        'book': {
          '_id': 'b1',
          'title': 'Hamlet',
          'author': 'William Shakespeare',
          'totalDurationMs': 1000,
        },
        'progress': {
          'currentChapterTitle': 'Act I',
          'positionMs': 100,
          'percentComplete': 50,
          'remainingMs': 3600000,
        },
      });

      expect(book.id, 'b1');
      expect(book.title, 'Hamlet');
      expect(book.chapterTitle, 'Act I');
      expect(book.positionMs, 100);
      expect(book.progress, 0.5);
      expect(book.formattedRemaining, contains('REMAINING'));
    });

    test('an entry with no book is left off the home screen', () {
      final home = HomeAudiobookData.fromJson(const {
        'continueListening': [
          {'progress': <String, Object>{}},
        ],
      });
      expect(home.continueListening, isEmpty);
    });
  });

  group('AudioBookDetailsController.ensureLoaded', () {
    late _FakeBooks books;

    setUp(() {
      Get.testMode = true;
      books = _FakeBooks();
      Get.put<AudioBookInterface>(books);
      Get.put(LikedAudiobooksController(), permanent: true);
    });
    tearDown(Get.reset);

    test('joins the load already running', () async {
      books.answers.add(
        Right(Success(data: AudiobookDetailsData.fromJson(_hamlet))),
      );
      final controller = AudioBookDetailsController();

      final loading = controller.loadDetails('b1');
      await controller.ensureLoaded('b1');
      await loading;

      expect(controller.firstChapter?.id, 'c1');
      expect(books.calls, 1);
    });

    test('retries a load that failed, keeping its error until then', () async {
      books.answers.addAll([
        Left(
          DataCRUDFailure(
            failure: Failure.socketFailure,
            fullError: 'No internet connection.',
          ),
        ),
        Right(Success(data: AudiobookDetailsData.fromJson(_hamlet))),
      ]);
      final controller = AudioBookDetailsController();

      await controller.loadDetails('b1');
      expect(controller.firstChapter, isNull);
      expect(controller.errorMessage.value, 'No internet connection.');

      await controller.ensureLoaded('b1');
      expect(controller.firstChapter?.id, 'c1');
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  group('series and chapter position', () {
    test('universe links read as prequel and sequel', () {
      final book = Book.fromJson({
        '_id': 'b2',
        'universe': [
          {'audiobookId': 'b1', 'relation': 'prequel'},
          {
            'audiobookId': {'_id': 'b3', 'title': 'Book 3'},
            'relation': 'sequel',
          },
          {'audiobookId': 'b9', 'relation': 'spin-off'},
          {'relation': 'sequel'},
        ],
      });

      final links = book.seriesLinks;
      expect(links.map((l) => l.audiobookId), ['b1', 'b3']);
      expect(links.map((l) => l.isSequel), [false, true]);
    });

    test('the player says which chapter of how many', () {
      final playing =
          NowPlayingContext(
              kind: NowPlayingKind.chapter,
              collectionId: 'b1',
              collectionTitle: 'Hamlet',
              entries: const [
                NowPlayingEntry(id: 'c1', title: 'Act I', label: 'Chapter 1'),
                NowPlayingEntry(id: 'c2', title: 'Act II', label: 'Chapter 2'),
                NowPlayingEntry(id: 'c3', title: 'Act III', label: 'Chapter 3'),
              ],
            )
            ..series.add(
              const SeriesEntry(
                id: 'b2',
                title: 'Hamlet II',
                relation: SeriesRelation.sequel,
              ),
            );

      expect(playing.position('c2'), 'Chapter 2 of 3');
      expect(playing.position('elsewhere'), '');
      expect(playing.heading, 'PLAYING FROM AUDIOBOOK');
      expect(playing.sequel?.id, 'b2');
      expect(playing.prequel, isNull);
    });
  });

  group('where Listen Now resumes', () {
    late _FakeBooks books;

    /// A two-chapter book whose saved progress is [progress].
    Map<String, dynamic> book(Map<String, dynamic>? progress) => {
      'book': {'_id': 'b1', 'title': 'Two Parts'},
      'chapters': [
        {'_id': 'c1', 'chapterNumber': 1, 'title': 'One', 'durationMs': 600000},
        {'_id': 'c2', 'chapterNumber': 2, 'title': 'Two', 'durationMs': 600000},
      ],
      'userProgress': progress,
    };

    Future<AudioBookDetailsController> load(
      Map<String, dynamic>? progress,
    ) async {
      books.answers.add(
        Right(Success(data: AudiobookDetailsData.fromJson(book(progress)))),
      );
      final controller = AudioBookDetailsController();
      await controller.loadDetails('b1');
      await controller.refreshResume();
      return controller;
    }

    setUp(() async {
      Get.testMode = true;
      await ProgressStore.clear();
      books = _FakeBooks();
      Get.put<AudioBookInterface>(books);
      Get.put(LikedAudiobooksController(), permanent: true);
    });
    tearDown(Get.reset);

    test(
      'carries on in the chapter and at the point the server saved',
      () async {
        final controller = await load({
          'currentChapterId': 'c2',
          'positionMs': 125000,
          'completed': false,
        });

        final point = controller.resumePoint.value;
        expect(point?.chapter.id, 'c2');
        expect(point?.startAt, const Duration(milliseconds: 125000));
      },
    );

    test('a chapter left at its very end moves on to the next', () async {
      final controller = await load({
        'currentChapterId': 'c1',
        'positionMs': 599000,
      });

      expect(controller.resumePoint.value?.chapter.id, 'c2');
      expect(controller.resumePoint.value?.startAt, Duration.zero);
    });

    test(
      'a finished book, or one never started, starts at chapter 1',
      () async {
        expect((await load({'completed': true})).resumePoint.value, isNull);
        expect((await load(null)).resumePoint.value, isNull);
      },
    );

    test('offline listening on this device is picked up too', () async {
      // What playing chapter 2 offline left on the device.
      ProgressStore.setCurrent('audiobook:b1', 'c2');
      ProgressStore.save('c2', 42000);

      final controller = await load(null);

      expect(controller.resumePoint.value?.chapter.id, 'c2');
      expect(
        controller.resumePoint.value?.startAt,
        const Duration(milliseconds: 42000),
      );
    });
  });
}
