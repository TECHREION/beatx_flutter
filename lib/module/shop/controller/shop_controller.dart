import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/shop_model.dart';

class ShopController extends GetxController {
  final selectedCategory = 0.obs;

  final banners = const <PromoBannerModel>[
    PromoBannerModel(
      title: 'Event Tickets',
      subtitle:
          'Minimalist aesthetics for the digital age. Designed by BeatsX Studio.',
      ctaText: 'Explore Live Events',
      accentColor: Color(0xFF3BDDEB),
      image: 'assets/image/genre_shop.png',
    ),
    PromoBannerModel(
      title: 'The Streetwear Capsule',
      subtitle:
          'Minimalist aesthetics for the digital age. Designed by BeatsX Studio.',
      ctaText: 'Explore Apparel',
      accentColor: Color(0xFF3BDDEB),
      image: 'assets/image/Overlay+Shadow (2).png',
      titleColor: Color(0xFF3BDDEB),
    ),
    PromoBannerModel(
      title: 'Accessory Pack',
      subtitle:
          'Tech-noir inspired everyday carry. From custom cables to holographic stickers.',
      ctaText: 'View More',
      accentColor: Color(0xFF56E768),
      image: 'assets/image/genre_hiphop_soul.png',
    ),
  ];

  final categories = const <ShopCategoryModel>[
    ShopCategoryModel(label: 'All Gear'),
    ShopCategoryModel(label: 'Apparel'),
    ShopCategoryModel(label: 'Vinyls'),
    ShopCategoryModel(label: 'Accessories'),
    ShopCategoryModel(label: 'Digital Art'),
  ];

  final products = const <ShopProductModel>[
    ShopProductModel(
      title: 'Oversized "Void" Hoodie',
      subtitle: 'Heavyweight Cotton / Prism Black',
      price: '85.00',
      currency: r'$',
      coinPrice: 50,
      image: 'assets/image/Container.png',
      isNew: true,
    ),
    ShopProductModel(
      title: 'Neon Pulse LP',
      subtitle: 'Limited Cyan Pressing',
      price: '250.00',
      currency: '৳',
      coinPrice: 50,
      image: 'assets/image/Album Art.png',
      discountLabel: '10%',
    ),
    ShopProductModel(
      title: 'Oversized "Void" Backpack',
      subtitle: 'Water-Resistant Tech-W...',
      price: '250.00',
      currency: '৳',
      coinPrice: 50,
      image: 'assets/image/Overlay+Border+OverlayBlur.png',
      discountLabel: '5%',
    ),
    ShopProductModel(
      title: 'Refraction Tee',
      subtitle: '100% Organic Cotton / W...',
      price: '260.00',
      currency: '৳',
      coinPrice: 50,
      image: 'assets/image/Album Art (1).png',
      isNew: true,
    ),
    ShopProductModel(
      title: 'Clipart Guitar',
      subtitle: 'Clipart guitar, old, classi...',
      price: '860.00',
      currency: '৳',
      coinPrice: 50,
      image: 'assets/image/Now Playing.png',
    ),
    ShopProductModel(
      title: 'Artist Outfit Casu...',
      subtitle: 'Welcome to [Cotton Clan]',
      price: '260.00',
      currency: '৳',
      coinPrice: 50,
      image: 'assets/image/Overlay+Shadow (2).png',
    ),
  ];

  final artistCollections = const <ArtistCollectionModel>[
    ArtistCollectionModel(
      name: 'CYBER-MIND X BEATX',
      genre: 'EXPERIMENTAL TECHNO',
      itemCount: 52,
      cover: 'assets/image/Overlay+Shadow.png',
    ),
    ArtistCollectionModel(
      name: 'LUNA SOUL SIGNATURE',
      genre: 'LO-FI BEATS',
      itemCount: 8,
      cover: 'assets/image/Overlay+Shadow (1).png',
    ),
    ArtistCollectionModel(
      name: 'THE VOID ANTHOLOGY',
      genre: 'INDUSTRIAL ROCK',
      itemCount: 24,
      cover: 'assets/image/a6.png',
    ),
  ];

  void selectCategory(int index) => selectedCategory.value = index;
}
