import 'package:get/get.dart';

import '../model/featured_video_model.dart';
import '../model/music_video_model.dart';

class WatchController extends GetxController {
  final featuredVideo = const FeaturedVideoModel(
    title: 'NEON\nREFRACTIONS',
    description:
        'Experience the visual odyssey of the year. Directed by Aethereal, starring the Prism collective.',
    tag: 'FEATURED PREMIERE',
  ).obs;

  final trendingVideos = const <MusicVideoModel>[
    MusicVideoModel(
      title: 'DeadLine Music',
      artist: 'Jukebox',
      meta: '1.2M views - 2 days ago',
      duration: '04:20',
      image: 'assets/image/image.png',
      videoAsset:
          'assets/video/mixkit-countryside-meadow-4075-hd-ready.mp4',
    ),
    MusicVideoModel(
      title: 'Bhalo Thake Mon',
      artist: 'Fahim Islam',
      meta: '890K views',
      duration: '04:20',
      image: 'assets/image/onboarding1.png',
      videoAsset:
          'assets/video/mixkit-highway-in-the-middle-of-a-mountain-range-4633-hd-ready.mp4',
    ),
    MusicVideoModel(
      title: 'Tor Lagiya',
      artist: 'Shomz Vai',
      meta: '450K views',
      duration: '04:20',
      image: 'assets/image/blackout.png',
      videoAsset: 'assets/video/mixkit-raft-going-slowly-down-a-river-1218-hd-ready.mp4',
    ),
  ].obs;
}
