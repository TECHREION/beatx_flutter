import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/category_model.dart';
import '../model/episode_model.dart';
import '../model/podcast_model.dart';
import '../model/podcaster_model.dart';

class PodcastController extends GetxController {
  final featuredIndex = 0.obs;

  final featuredPodcasts = const <PodcastModel>[
    PodcastModel(
      title: 'DeadLine Adda',
      host: 'Teamature',
      description:
          'Exploring the intersections of artificial intelligence and human psychology...',
      image: 'assets/image/Featured Podcast 1.png',
      badge: 'TRENDING NOW',
    ),
    PodcastModel(
      title: 'Frequency Response',
      host: 'Fahim Islam',
      description:
          'Fresh conversations on culture, creativity, and sound design.',
      image: 'assets/image/Featured Podcast 1.png',
      badge: 'CURATED PICK',
    ),
  ];

  final categories = const <CategoryModel>[
    CategoryModel(
      title: 'True Crime',
      image: 'assets/image/podcast_category_true_crime.png',
      tint: Color(0xFF4D314F),
    ),
    CategoryModel(
      title: 'Comedy',
      image: 'assets/image/podcast_category_comedy.png',
      tint: Color(0xFF176064),
    ),
    CategoryModel(
      title: 'Tech',
      image: 'assets/image/podcast_category_tech.png',
      tint: Color(0xFF4E563B),
    ),
  ];

  final podcasters = const <PodcasterModel>[
    PodcasterModel(name: 'Fahim Islam', image: 'assets/image/a1.png'),
    PodcasterModel(name: 'SARAH V.', image: 'assets/image/a2.png'),
    PodcasterModel(name: 'DR. THORNE', image: 'assets/image/a3.png'),
    PodcasterModel(
      name: 'MARCUS K.',
      image: 'assets/image/podcast_avatar_marcus.png',
    ),
  ];

  final episodes = const <EpisodeModel>[
    EpisodeModel(
      title: 'The Crime Renaissance',
      subtitle: 'Why modern producers are...',
      meta: '45 min - Frequency Response',
      image: 'assets/image/Episode 1.png',
      audioAsset: 'audio/music5.m4a',
      isNew: true,
    ),
    EpisodeModel(
      title: 'S04 E12: Silicon Dreams',
      subtitle: 'What happens when the AI...',
      meta: '58 min - Neural Networks',
      image: 'assets/image/Episode 2.png',
      audioAsset: 'audio/music6.m4a',
    ),
    EpisodeModel(
      title: 'Quantum Supremacy & Audio',
      subtitle: 'How quantum computing will...',
      meta: '1h 12m - Tech Talk',
      image: 'assets/image/Episode 3.png',
      audioAsset: 'audio/music1.m4a',
    ),
  ];

  PodcastModel get featuredPodcast => featuredPodcasts[featuredIndex.value];

  void showPreviousFeatured() {
    featuredIndex.value =
        (featuredIndex.value - 1 + featuredPodcasts.length) %
        featuredPodcasts.length;
  }

  void showNextFeatured() {
    featuredIndex.value = (featuredIndex.value + 1) % featuredPodcasts.length;
  }
}
