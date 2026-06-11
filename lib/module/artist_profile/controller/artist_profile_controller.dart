import 'package:get/get.dart';

import '../model/artist_profile_model.dart';

class ArtistProfileController extends GetxController {
  final selectedTab = 0.obs;
  final isFollowing = false.obs;

  final artist = const ArtistProfileModel(
    name: 'Tashrif Khan',
    rank: '#10',
    monthlyListeners: '1.2m monthly listeners',
    bio:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Turpis '
        'adipiscing vestibulum orci enim, nascetur vitae',
    heroImage: 'assets/image/Overlay+Shadow (2).png',
    songs: [
      ArtistSongModel(
        rank: '01',
        title: 'Badsah Pulse',
        plays: '42.5M plays',
        cover: 'assets/image/Container.png',
      ),
      ArtistSongModel(
        rank: '02',
        title: 'Glow Drive',
        plays: '38.1M plays',
        cover: 'assets/image/Album Art.png',
      ),
      ArtistSongModel(
        rank: '03',
        title: 'Fractal Theory',
        plays: '29.8M plays',
        cover: 'assets/image/Album Art (1).png',
      ),
    ],
    playlistTitle: 'The Best of Tashrif Khan',
    playlistCover: 'assets/image/Overlay+Border+OverlayBlur.png',
    albums: [
      AlbumModel(
        title: 'Synth Horizon',
        type: 'Album',
        year: '2024',
        cover: 'assets/image/Container.png',
      ),
      AlbumModel(
        title: 'Synth Horizon',
        type: 'Album',
        year: '2024',
        cover: 'assets/image/Album Art.png',
      ),
      AlbumModel(
        title: 'Static D',
        type: 'EP',
        year: '2022',
        cover: 'assets/image/Album Art (1).png',
      ),
    ],
    tourDates: [
      TourDateModel(
        month: 'NOV',
        day: '24',
        venue: 'Neon City Arena',
        location: 'Tokyo, Japan',
        isSoldOut: false,
      ),
      TourDateModel(
        month: 'DEC',
        day: '02',
        venue: 'The Grid Pavilion',
        location: 'Berlin, Germany',
        isSoldOut: false,
      ),
      TourDateModel(
        month: 'DEC',
        day: '15',
        venue: 'Sphere One',
        location: 'London, UK',
        isSoldOut: true,
      ),
    ],
    similarArtists: [
      SimilarArtistModel(
        name: 'Fahim Islam',
        image: 'assets/image/Overlay+Shadow.png',
      ),
      SimilarArtistModel(name: 'Nabila', image: 'assets/image/a2.png'),
      SimilarArtistModel(name: 'Jisan Khan', image: 'assets/image/a3.png'),
      SimilarArtistModel(
        name: 'Kazi Shuvo',
        image: 'assets/image/Overlay+Shadow (1).png',
      ),
    ],
    products: [
      ArtistProductModel(
        title: 'Oversized "Void" Hoodie',
        subtitle: 'Heavyweight Cotton / Prism Black',
        price: '85.00',
        currency: r'$',
        coinPrice: 50,
        image: 'assets/image/Container.png',
      ),
      ArtistProductModel(
        title: 'Neon Pulse LP',
        subtitle: 'Limited Cyan Pressing',
        price: '250.00',
        currency: '৳',
        coinPrice: 50,
        image: 'assets/image/Album Art.png',
      ),
      ArtistProductModel(
        title: 'Oversized "Void" Backpack',
        subtitle: 'Water-Resistant Tech-Wear',
        price: '250.00',
        currency: '৳',
        coinPrice: 50,
        image: 'assets/image/Overlay+Border+OverlayBlur.png',
      ),
      ArtistProductModel(
        title: 'Refraction Tee',
        subtitle: '100% Organic Cotton / White',
        price: '250.00',
        currency: '৳',
        coinPrice: 50,
        image: 'assets/image/Album Art (1).png',
      ),
      ArtistProductModel(
        title: 'Clipart Guitar',
        subtitle: 'Clipart guitar, old, classic,',
        price: '850.00',
        currency: '৳',
        coinPrice: 50,
        image: 'assets/image/Now Playing.png',
      ),
      ArtistProductModel(
        title: 'Artist Outfit Casual',
        subtitle: 'Welcome to [Cotton Clan]',
        price: '250.00',
        currency: '৳',
        coinPrice: 50,
        image: 'assets/image/Overlay+Shadow (2).png',
      ),
    ],
  );

  void toggleFollow() => isFollowing.toggle();

  void selectTab(int index) => selectedTab.value = index;
}
