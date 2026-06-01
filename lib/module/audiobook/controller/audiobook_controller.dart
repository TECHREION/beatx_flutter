import 'package:get/get.dart';

import '../model/audiobook_model.dart';
import '../model/bestseller_model.dart';
import '../model/genre_model.dart';

class AudiobookController extends GetxController {
  final continueListening = const AudiobookModel(
    title: 'Project Hail Mary',
    author: 'Andy Weir',
    narrator: 'Ray Porter',
    cover: 'assets/image/5.png',
    chapter: 'Chapter 14: The Eridian',
    progress: 0.72,
    remaining: '4 HOURS REMAINING',
  ).obs;

  final queuedBook = const AudiobookModel(
    title: 'The Children Of Bangladeshi',
    author: 'Jason Laure',
    narrator: 'Maya Khan',
    cover: 'assets/image/blackout.png',
    chapter: 'Chapter 08: The Return',
    progress: 0.72,
    remaining: '4 HOURS REMAINING',
  ).obs;

  final genres = const <GenreModel>[
    GenreModel(title: 'All Genres', isSelected: true),
    GenreModel(title: 'Fiction'),
    GenreModel(title: 'Non-Fiction'),
    GenreModel(title: 'Biography'),
    GenreModel(title: 'Mystery'),
    GenreModel(title: 'Fantasy'),
    GenreModel(title: 'Sci-Fi'),
  ].obs;

  final newReleases = const <AudiobookModel>[
    AudiobookModel(
      title: 'The Prism Theory',
      author: 'Elena Valery',
      narrator: 'Arif Rahman',
      cover: 'assets/image/2.png',
      chapter: 'Chapter 01',
      progress: 0,
      remaining: '',
    ),
    AudiobookModel(
      title: 'Digital Dreams',
      author: 'Marcus Thorne',
      narrator: 'Leah Bose',
      cover: 'assets/image/blackout.png',
      chapter: 'Chapter 01',
      progress: 0,
      remaining: '',
    ),
    AudiobookModel(
      title: 'Neural Stories',
      author: 'Nadia Islam',
      narrator: 'Ray Porter',
      cover: 'assets/image/Robot.png',
      chapter: 'Chapter 01',
      progress: 0,
      remaining: '',
    ),
  ].obs;

  final bestsellers = const <BestsellerModel>[
    BestsellerModel(
      rank: '01',
      title: 'Badsah Namdar',
      author: 'Humayun Ahmed',
      cover: 'assets/image/3.png',
      trendUp: true,
    ),
    BestsellerModel(
      rank: '02',
      title: 'Amazonio',
      author: 'James Rollis',
      cover: 'assets/image/4.png',
      trendUp: true,
    ),
    BestsellerModel(
      rank: '03',
      title: 'Ondhokare Golpo',
      author: 'Ovik Sarkar',
      cover: 'assets/image/1.png',
      trendUp: false,
    ),
  ].obs;
}
