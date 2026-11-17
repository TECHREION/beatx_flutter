import 'dart:async';
import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../onbording/common/app_logo.dart';
import '../../services/onboarding_service.dart';

class ArtistModel {
  final String id;
  final String name;

  /// A network avatar URL, an asset path, or empty for a placeholder.
  final String image;
  bool selected;

  ArtistModel({
    this.id = '',
    required this.name,
    required this.image,
    this.selected = false,
  });
}

class GenreModel {
  final String id;
  final String name;
  bool selected;

  GenreModel({this.id = '', required this.name, this.selected = false});
}

class SelectArtistScreen extends StatelessWidget {
  const SelectArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InterestSelectionScreen();
  }
}

/// Listener onboarding: pick artists and genres, or skip.
///
/// Shown after a sign-in that reports `onboardingCompleted: false`. Artists
/// come from `/discovery/recommended-artists` (and `/users/artists?q=` while
/// searching), genres from `/genre`. Continue saves the picks with
/// `PATCH /users/me/artists` and `/users/me/genres`; both Continue and Skip
/// then save `onboardingCompleted: true` so the screen is not shown again.
class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key, this.onContinue, this.service});

  final VoidCallback? onContinue;

  /// Replaces the API calls in tests.
  final OnboardingService? service;

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

  late final OnboardingService? _service =
      widget.service ??
      (Get.isRegistered<AuthorizedPigeon>()
          ? OnboardingService(Get.find<AuthorizedPigeon>())
          : null);

  /// Suggested artists, plus any picked from search results so a pick
  /// survives clearing the search.
  final List<ArtistModel> _artists = [];
  final List<GenreModel> _genres = [];

  /// Artist rows answering the current search, when one is running.
  List<ArtistModel>? _searchResults;
  Timer? _searchDebounce;
  int _searchSeq = 0;

  bool _loading = true;
  bool _saving = false;
  String _loadError = '';

  int get _selectedCount {
    final artistCount = _artists.where((artist) => artist.selected).length;
    final genreCount = _genres.where((genre) => genre.selected).length;
    return artistCount + genreCount;
  }

  bool get _canContinue => _selectedCount >= _minimumSelections && !_saving;

  List<ArtistModel> get _filteredArtists {
    if (_query.isEmpty) return _artists;
    final remote = _searchResults;
    if (remote != null) return remote;
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = _service;
    if (service == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _loadError = '';
    });

    final results = await Future.wait([
      service.recommendedArtists(),
      service.genres(),
    ]);
    if (!mounted) return;

    final artistResult = results[0];
    final genreResult = results[1];
    setState(() {
      artistResult.fold((failure) => _loadError = failure.uiMessage, (ok) {
        final rows = (ok.data as List<OnboardingArtist>?) ?? const [];
        _artists
          ..clear()
          ..addAll(rows.map(_artistOf));
      });
      genreResult.fold((failure) => _loadError = failure.uiMessage, (ok) {
        final rows = (ok.data as List<OnboardingGenre>?) ?? const [];
        _genres
          ..clear()
          ..addAll(rows.map((g) => GenreModel(id: g.id, name: g.name)));
      });
      _loading = false;
    });
  }

  ArtistModel _artistOf(OnboardingArtist artist) =>
      ArtistModel(id: artist.id, name: artist.name, image: artist.avatar ?? '');

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
      _searchResults = null;
    });
    _searchDebounce?.cancel();
    final service = _service;
    if (_query.isEmpty || service == null) return;

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final seq = ++_searchSeq;
      final result = await service.searchArtists(value.trim());
      if (!mounted || seq != _searchSeq) return;
      result.fold((_) {}, (ok) {
        final byId = {for (final a in _artists) a.id: a};
        setState(() {
          _searchResults = (ok.data ?? const <OnboardingArtist>[])
              .map((row) => byId[row.id] ?? _artistOf(row))
              .toList();
        });
      });
    });
  }

  void _toggleArtist(ArtistModel artist) {
    setState(() {
      artist.selected = !artist.selected;
      // A pick made from search results is kept once the search is cleared.
      if (artist.selected && !_artists.contains(artist)) _artists.add(artist);
    });
  }

  void _toggleGenre(GenreModel genre) {
    setState(() {
      genre.selected = !genre.selected;
    });
  }

  Future<void> _finish({required bool skip}) async {
    if (_saving) return;
    final service = _service;
    if (service == null) {
      widget.onContinue?.call();
      return;
    }

    setState(() => _saving = true);
    final result = await service.complete(
      artistIds: skip
          ? const []
          : [
              for (final a in _artists)
                if (a.selected && a.id.isNotEmpty) a.id,
            ],
      genreIds: skip
          ? const []
          : [
              for (final g in _genres)
                if (g.selected && g.id.isNotEmpty) g.id,
            ],
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold((failure) {
      // A genre removed meanwhile is a 400; reload the list so the next try
      // only sends current ids.
      if (failure.uiMessage.toLowerCase().contains('genre')) _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.uiMessage)));
    }, (_) => widget.onContinue?.call());
  }

  void _continue() {
    if (!_canContinue) {
      if (_saving) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }
    _finish(skip: false);
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
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 16),
                      const _InterestTabs(),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF40DDEB),
                          ),
                        )
                      : _loadError.isNotEmpty &&
                            _artists.isEmpty &&
                            _genres.isEmpty
                      ? Center(
                          child: TextButton(
                            onPressed: _load,
                            child: Text(
                              '$_loadError\nTap to retry',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFA9A3AC)),
                            ),
                          ),
                        )
                      : TabBarView(
                          children: [
                            _ArtistGrid(
                              artists: _filteredArtists,
                              onTap: _toggleArtist,
                            ),
                            _GenreGrid(
                              genres: _filteredGenres,
                              onTap: _toggleGenre,
                            ),
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
                        busy: _saving,
                      ),
                      TextButton(
                        onPressed: _saving ? null : () => _finish(skip: true),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Color(0xFFA9A3AC),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                    backgroundImage: _imageOf(image),
                    child: image.isEmpty
                        ? const Icon(Icons.person, color: Colors.white54)
                        : null,
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

ImageProvider? _imageOf(String image) {
  if (image.isEmpty) return null;
  if (image.startsWith('http')) return CachedNetworkImageProvider(image);
  return AssetImage(image);
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.gradient,
    required this.onTap,
    this.busy = false,
  });

  final bool busy;
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
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF111113),
                  ),
                )
              : const Text(
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
