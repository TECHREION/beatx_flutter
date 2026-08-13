import 'package:flutter/material.dart';

import '../../model/podcast_home_model.dart';

class PodcasterCard extends StatelessWidget {
  const PodcasterCard({super.key, required this.podcasters});

  final List<Podcaster> podcasters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 24,
            spacing: 28,
            children: [
              for (final podcaster in podcasters)
                SizedBox(
                  width: 78,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFC845), Color(0xFF40DDEB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF111113),
                          backgroundImage:
                              podcaster.artistAvatar?.isNotEmpty == true
                              ? NetworkImage(podcaster.artistAvatar!)
                              : null,
                          onBackgroundImageError:
                              podcaster.artistAvatar?.isNotEmpty == true
                              ? (_, _) {}
                              : null,
                          child: podcaster.artistAvatar?.isNotEmpty == true
                              ? null
                              : Text(
                                  _initials(podcaster.stageName ?? podcaster.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        podcaster.stageName?.isNotEmpty == true
                            ? podcaster.stageName!
                            : podcaster.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 23),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('VIEW ALL CREATORS'),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
