import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audiobook/presentation/screen/audiobook_screen.dart';
import 'home/presentation/screens/home_screen.dart';
import 'podcast/presentation/screen/podcast_screen.dart';
import 'podcast/presentation/widget/mini_player.dart';
import 'watch/presentation/screen/watch_screen.dart';

class AppGround extends StatelessWidget {
  AppGround({super.key, this.initialIndex = 0})
    : currentIndex = initialIndex.obs;

  final int initialIndex;
  final RxInt currentIndex;

  final List<Widget> pages = const [
    HomeScreen(),
    WatchScreen(),
    PodcastScreen(),
    AudiobookScreen(),
    Scaffold(backgroundColor: Color(0xFF0B0B0C)),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.headphones_rounded, label: 'Listen'),
    _NavItemData(icon: Icons.play_circle_fill_rounded, label: 'Watch'),
    _NavItemData(icon: Icons.mic_external_on_rounded, label: 'Podcast'),
    _NavItemData(icon: Icons.menu_book_rounded, label: 'Audiobook'),
    _NavItemData(icon: Icons.storefront_rounded, label: 'SHOP'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: Obx(() => pages[currentIndex.value]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFF0B0B0C),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                if (currentIndex.value == 1 || currentIndex.value == 3) {
                  return const SizedBox.shrink();
                }

                if (currentIndex.value == 2) {
                  return const PodcastMiniPlayer();
                }

                return const _MiniPlayer();
              }),
              Container(
                height: 72,
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF202020),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Obx(
                  () => Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final selected = currentIndex.value == index;
                      return Expanded(
                        child: _NavItem(
                          item: item,
                          selected: selected,
                          onTap: () => currentIndex.value = index,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF17181A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF124A56), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(width: 44, height: 44, child: _MiniArtwork()),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bhalo Thake Mon',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fahim Islam',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFAAA5AD),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.skip_previous_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: Color(0xFF111113),
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF57E8C9), Color(0xFF342F89)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Image.asset('assets/image/Now Playing.png', fit: BoxFit.cover),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF44E5F1) : const Color(0xFF9B989F);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 54 : 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0A5C68) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: color, size: 21),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
