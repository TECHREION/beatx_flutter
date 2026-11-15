import 'package:beatx_flutter/module/artist_profile/model/artist_profile_model.dart';
import 'package:beatx_flutter/module/artist_profile/presentation/screens/artist_product_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('product cards do not overflow at text scale $scale', (
      tester,
    ) async {
      // The width that overflowed on an iPhone 17: two 179px cards.
      tester.view.physicalSize = const Size(402 * 3, 874 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ArtistProductGrid(
                  products: [
                    for (var i = 0; i < 4; i++)
                      const ArtistProductModel(
                        title: 'Aurthohin Logo Cap with a long name',
                        subtitle: 'Accessories',
                        price: '৳600.00',
                        currency: '',
                        coinPrice: 50,
                        image: '',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
