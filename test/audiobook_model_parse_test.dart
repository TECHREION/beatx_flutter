// import 'dart:convert';
// import 'package:beatx_flutter/module/audiobook/model/audiobook_model.dart';
// import 'package:flutter_test/flutter_test.dart';

// const _payload = '''
// {"status":true,"message":"Success","data":{"continueListening":[],"newReleases":[
// {"totalChapters":0,"_id":"a1","title":"Project Hail Mary","author":"Andy Weir","coverUrl":"https://x/1.webp","totalDurationMs":15109816,"genre":{"_id":"g1","name":"rock"},"ratingAverage":0,"publishedAt":"2021-05-04T00:00:00.000Z"},
// {"_id":"a4","title":"Project Hail Mary 2","author":"Andy Weir","coverUrl":"https://x/4.webp","totalDurationMs":37774540,"genre":{"_id":"g2","name":"electronic"},"ratingAverage":0,"publishedAt":"2021-05-04T00:00:00.000Z","totalChapters":6}],
// "bestsellers":[{"_id":"a4","title":"Project Hail Mary 2","author":"Andy Weir","coverUrl":"https://x/4.webp","ratingAverage":0,"bestsellerRank":1,"trendDirection":"up"},
// {"_id":"a1","title":"Project Hail Mary","author":"Andy Weir","coverUrl":"https://x/1.webp","ratingAverage":0,"bestsellerRank":2,"trendDirection":"down"}],
// "trending":[{"_id":"a4","title":"Project Hail Mary 2","author":"Andy Weir","coverUrl":"https://x/4.webp","totalDurationMs":37774540,"genre":{"_id":"g2","name":"electronic"},"ratingAverage":0,"playCountWeek":4,"trendDirection":"up","totalChapters":6}]}}
// ''';

// void main() {
//   test('parses the audiobook home payload', () {
//     final body = jsonDecode(_payload) as Map<String, dynamic>;
//     final home = HomeAudiobookData.fromJson(body['data'] as Map<String, dynamic>);

//     expect(home.isEmpty, isFalse);
//     expect(home.continueListening, isEmpty);
//     expect(home.newReleases.length, 2);
//     expect(home.newReleases.first.genreName, 'rock');
//     expect(home.newReleases[1].totalChapters, 6);
//     expect(home.newReleases[1].formattedDuration, '10h 29m');
//     expect(home.newReleases.first.publishedAt?.year, 2021);

//     expect(home.bestsellers.first.formattedRank, '01');
//     expect(home.bestsellers.first.isTrendingUp, isTrue);
//     expect(home.bestsellers[1].isTrendingUp, isFalse);

//     expect(home.trending.first.playCountWeek, 4);
//     expect(home.trending.first.isTrendingUp, isTrue);
//   });

//   test('continue listening progress is safe when duration is zero', () {
//     final book = ContinueListeningBook.fromJson({
//       '_id': 'a1', 'title': 't', 'author': 'a', 'totalDurationMs': 0, 'positionMs': 500,
//     });
//     expect(book.progress, 0);
//     expect(book.formattedRemaining, '');
//   });
// }
