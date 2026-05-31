import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../onbording/common/app_logo.dart';

class ArtistModel {
  final String name;
  final String image;
  bool selected;

  ArtistModel({required this.name, required this.image, this.selected = false});
}

class GenreModel {
  final String name;
  bool selected;

  GenreModel({required this.name, this.selected = false});
}

class SelectArtistScreen extends StatelessWidget {
  const SelectArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InterestSelectionScreen();
  }
}

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const int _minimumSelections = 3;
  static const LinearGradient _buttonGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final List<ArtistModel> _artists = [
    ArtistModel(name: 'Ariana Nova', image: 'assets/image/image.png'),
    ArtistModel(name: 'The Weeknd', image: 'assets/image/Robot.png'),
    ArtistModel(name: 'Billie Ray', image: 'assets/image/onboarding1.png'),
    ArtistModel(name: 'Drake Stone', image: 'assets/image/1.png'),
    ArtistModel(name: 'Taylor Bloom', image: 'assets/image/2.png'),
    ArtistModel(name: 'Post River', image: 'assets/image/3.png'),
    ArtistModel(name: 'Sia Moon', image: 'assets/image/4.png'),
    ArtistModel(name: 'Bruno Vale', image: 'assets/image/5.png'),
    ArtistModel(name: 'Dua Sky', image: 'assets/image/message.png'),
  ];

  final List<GenreModel> _genres = [
    GenreModel(name: 'Pop'),
    GenreModel(name: 'Hip-Hop'),
    GenreModel(name: 'Rock'),
    GenreModel(name: 'R&B'),
    GenreModel(name: 'Electronic'),
    GenreModel(name: 'Jazz'),
    GenreModel(name: 'Afrobeats'),
    GenreModel(name: 'Country'),
    GenreModel(name: 'Indie'),
    GenreModel(name: 'Latin'),
    GenreModel(name: 'Classical'),
    GenreModel(name: 'Lo-Fi'),
  ];

  int get _selectedCount {
    final artistCount = _artists.where((artist) => artist.selected).length;
    final genreCount = _genres.where((genre) => genre.selected).length;
    return artistCount + genreCount;
  }

  bool get _canContinue => _selectedCount >= _minimumSelections;

  List<ArtistModel> get _filteredArtists {
    if (_query.isEmpty) return _artists;
    return _artists
        .where((artist) => artist.name.toLowerCase().contains(_query))
        .toList();
  }

  List<GenreModel> get _filteredGenres {
    if (_query.isEmpty) return _genres;
    return _genres
        .where((genre) => genre.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleArtist(ArtistModel artist) {
    setState(() {
      artist.selected = !artist.selected;
    });
  }

  void _toggleGenre(GenreModel genre) {
    setState(() {
      genre.selected = !genre.selected;
    });
  }

  void _continue() {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }

    widget.onContinue?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0B0C),
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0B0C),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      const AppLogo(height: 74, width: 190),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose Your Interests',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select at least $_minimumSelections artists or genres',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFA9A3AC),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SearchField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _query = value.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const _InterestTabs(),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ArtistGrid(
                        artists: _filteredArtists,
                        onTap: _toggleArtist,
                      ),
                      _GenreGrid(genres: _filteredGenres, onTap: _toggleGenre),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        '$_selectedCount selected',
                        style: TextStyle(
                          color: _canContinue
                              ? const Color(0xFF40DDEB)
                              : const Color(0xFFA9A3AC),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ContinueButton(
                        enabled: _canContinue,
                        gradient: _buttonGradient,
                        onTap: _continue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          hintText: 'Enter your favorite here',
          hintStyle: TextStyle(color: Colors.white54),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _InterestTabs extends StatelessWidget {
  const _InterestTabs();

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      indicatorColor: Color(0xFF40DDEB),
      labelColor: Color(0xFF40DDEB),
      unselectedLabelColor: Colors.white54,
      dividerColor: Color(0xFF232326),
      labelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      tabs: [
        Tab(text: 'Artist'),
        Tab(text: 'Genre'),
      ],
    );
  }
}

class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({required this.artists, required this.onTap});

  final List<ArtistModel> artists;
  final ValueChanged<ArtistModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const _EmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 18,
        crossAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistCard(
          name: artist.name,
          image: artist.image,
          selected: artist.selected,
          onTap: () => onTap(artist),
        );
      },
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.genres, required this.onTap});

  final List<GenreModel> genres;
  final ValueChanged<GenreModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const _EmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.2,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return GenreChip(
          title: genre.name,
          selected: genre.selected,
          onTap: () => onTap(genre),
        );
      },
    );
  }
}

class GenreChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const GenreChip({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF3A3A3A),
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  final String name;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  const ArtistCard({
    super.key,
    required this.name,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF40DDEB)
                          : const Color(0xFF2D2D30),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF1A1A1D),
                    backgroundImage: AssetImage(image),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF44E067),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.15,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.gradient,
    required this.onTap,
  });

  final bool enabled;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: gradient,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              color: Color(0xFF111113),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No matches found',
        style: TextStyle(
          color: Color(0xFFA9A3AC),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
