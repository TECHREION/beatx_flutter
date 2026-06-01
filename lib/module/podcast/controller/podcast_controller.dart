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
      image: 'assets/image/image.png',
      badge: 'TRENDING NOW',
    ),
    PodcastModel(
      title: 'Frequency Response',
      host: 'Fahim Islam',
      description:
          'Fresh conversations on culture, creativity, and sound design.',
      image: 'assets/image/onboarding1.png',
      badge: 'CURATED PICK',
    ),
  ];

  final categories = const <CategoryModel>[
    CategoryModel(
      title: 'True Crime',
      image: 'assets/image/blackout.png',
      tint: Color(0xFF4D314F),
    ),
    CategoryModel(
      title: 'Comedy',
      image: 'assets/image/e.png',
      tint: Color(0xFF176064),
    ),
    CategoryModel(
      title: 'Tech',
      image: 'assets/image/Robot.png',
      tint: Color(0xFF4E563B),
    ),
  ];

  final podcasters = const <PodcasterModel>[
    PodcasterModel(name: 'Fahim Islam', image: 'assets/image/1.png'),
    PodcasterModel(name: 'SARAH V.', image: 'assets/image/2.png'),
    PodcasterModel(name: 'DR. THORNE', image: 'assets/image/3.png'),
    PodcasterModel(name: 'MARCUS K.', image: 'assets/image/4.png'),
  ];

  final episodes = const <EpisodeModel>[
    EpisodeModel(
      title: 'The Crime Renaissance',
      subtitle: 'Why modern producers are...',
      meta: '45 min - Frequency Response',
      image: 'assets/image/blackout.png',
      isNew: true,
    ),
    EpisodeModel(
      title: 'S04 E12: Silicon Dreams',
      subtitle: 'What happens when the AI...',
      meta: '58 min - Neural Networks',
      image: 'assets/image/2.png',
    ),
    EpisodeModel(
      title: 'Quantum Supremacy & Audio',
      subtitle: 'How quantum computing will...',
      meta: '1h 12m - Tech Talk',
      image: 'assets/image/3.png',
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
