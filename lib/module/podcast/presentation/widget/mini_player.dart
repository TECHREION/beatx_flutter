import 'package:flutter/material.dart';

class PodcastMiniPlayer extends StatelessWidget {
  const PodcastMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151617),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF124A56), width: 1),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/image/Now Playing.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
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
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: Color(0xFF111113),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
