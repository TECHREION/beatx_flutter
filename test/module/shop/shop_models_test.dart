import 'package:beatx_flutter/module/shop/model/event_model.dart';
import 'package:beatx_flutter/module/shop/model/product_model.dart';
import 'package:beatx_flutter/module/shop/model/purchase_model.dart';
import 'package:beatx_flutter/module/shop/model/shop_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shop.dart';

void main() {
  group('ShopProduct', () {
    test('reads the server money string and keeps paisa for maths', () {
      expect(tShirt.price, 2999);
      expect(tShirt.priceDisplay, '৳29.99');
    });

    test('sizes fall back to availableSizes, with stock unknown', () {
      expect(tShirt.sizes.map((size) => size.name), ['S', 'M']);
      expect(tShirt.sizes.first.stock, isNull);
      expect(tShirt.sizes.first.isAvailable, isTrue);
    });

    test('per-size stock greys out what ran out', () {
      final product = ShopProduct.fromJson(const {
        '_id': 'p',
        'hasSizeVariants': true,
        'stock': 5,
        'variants': [
          {'size': 'S', 'stock': 0},
          {'size': 'M', 'stock': 5},
        ],
      });
      expect(product.sizes.first.isAvailable, isFalse);
      expect(product.sizes.last.isAvailable, isTrue);
    });

    test('a colour out of stock is unavailable when colours track stock', () {
      expect(tShirt.isColorAvailable(tShirt.colors[0]), isTrue);
      expect(tShirt.isColorAvailable(tShirt.colors[1]), isFalse);
      expect(tShirt.colors[1].swatch, const Color(0xFF8B5CF6));
    });

    test('colours all at zero on a stocked product are only labels', () {
      // As "Updated Product Title" on the test server: stock 12, colours 0.
      final product = ShopProduct.fromJson(const {
        '_id': 'p',
        'stock': 12,
        'colorVariants': [
          {'name': 'Black', 'hex': '#000000', 'stock': 0},
        ],
      });
      expect(product.isColorAvailable(product.colors.single), isTrue);
    });

    test('a missing money string reads as null, not a computed amount', () {
      final product = ShopProduct.fromJson(const {'_id': 'p', 'price': 100});
      expect(product.priceDisplay, isNull);
    });
  });

  test('a category slug becomes a chip label', () {
    expect(ShopFilterOption.fromSlug('digital-art').label, 'Digital Art');
    expect(ShopFilterOption.fromSlug('digital-art').value, 'digital-art');
  });

  group('events', () {
    test('a tier without remaining works it out', () {
      final tier = TicketTier.fromJson(const {
        '_id': 't',
        'name': 'General',
        'quantity': 10,
        'sold': 10,
      });
      expect(tier.remaining, 0);
      expect(tier.isSoldOut, isTrue);
    });

    test('the day is the one stored, not moved by the time zone', () {
      final event = ShopEvent.fromJson(const {
        '_id': 'e',
        'eventDate': '2026-12-01T18:00:00.000Z',
        'eventTime': '18:00',
      });
      expect(event.dateLabel, 'Dec 1, 2026');
    });

    test('availability becomes tags', () {
      final low = ShopEvent.fromJson(const {
        '_id': 'e',
        'eventType': 'concert',
        'availability': 'low',
      });
      expect(low.tags, ['CONCERT', 'LOW AVAILABILITY']);
      final out = ShopEvent.fromJson(const {
        '_id': 'e',
        'availability': 'sold_out',
      });
      expect(out.isSoldOut, isTrue);
      expect(out.tags, ['SOLD OUT']);
    });

    test('a deleted event leaves the ticket readable', () {
      final ticket = TicketOrder.fromJson(const {
        '_id': 'k',
        'status': 'paid',
        'eventTitle': 'Old Show',
        'entryCode': 'ABCD1234',
        'event': null,
      });
      expect(ticket.event, isNull);
      expect(ticket.eventTitle, 'Old Show');
      expect(ticket.entryCode, 'ABCD1234');
    });
  });

  group('purchases', () {
    test('statuses parse, and anything unknown stays pending', () {
      expect(PurchaseStatus.parse('paid'), PurchaseStatus.paid);
      expect(PurchaseStatus.parse('expired'), PurchaseStatus.expired);
      expect(PurchaseStatus.parse('???'), PurchaseStatus.pending);
    });

    test('a null payment means nothing is due', () {
      expect(PaymentInfo.fromJson(null), isNull);
      expect(
        PaymentInfo.fromJson(const {'redirectUrl': 'https://pay'})?.redirectUrl,
        'https://pay',
      );
    });

    test('an order line sends only what was chosen', () {
      expect(const OrderItemRequest(productId: 'p', quantity: 2).toJson(), {
        'productId': 'p',
        'quantity': 2,
      });
      expect(
        const OrderItemRequest(
          productId: 'p',
          quantity: 1,
          size: 'M',
          color: 'Black',
        ).toJson(),
        {'productId': 'p', 'quantity': 1, 'size': 'M', 'color': 'Black'},
      );
    });
  });
}
