import 'package:beatx_flutter/core/theme/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] at a given logical screen size, the way a phone or a tablet
/// would hand it to the app.
///
/// The view is resized rather than just the MediaQuery: a MediaQuery on its
/// own reports a size while the widget underneath still gets laid out against
/// the default 800x600 test surface, which is not what is being tested here.
Future<BuildContext> pumpAt(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  late BuildContext captured;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) {
          captured = context;
          return child;
        },
      ),
    ),
  );
  return captured;
}

const _phone = Size(390, 844);
const _tabletPortrait = Size(834, 1194);
const _tabletLandscape = Size(1194, 834);

void main() {
  group('form factor', () {
    testWidgets('splits phone, tablet and desktop at the breakpoints', (
      tester,
    ) async {
      var context = await pumpAt(tester, _phone, const SizedBox());
      expect(context.formFactor, FormFactor.phone);
      expect(context.isPhone, isTrue);
      expect(context.isWide, isFalse);

      context = await pumpAt(tester, _tabletPortrait, const SizedBox());
      expect(context.formFactor, FormFactor.tablet);
      expect(context.isWide, isTrue);
      expect(context.isSplitReady, isFalse);

      context = await pumpAt(tester, _tabletLandscape, const SizedBox());
      expect(context.formFactor, FormFactor.desktop);
      expect(context.isSplitReady, isTrue);
    });

    testWidgets('responsive() falls back down the chain', (tester) async {
      final context = await pumpAt(tester, _tabletPortrait, const SizedBox());
      // No tablet value given, so it takes the phone one rather than the
      // desktop one.
      expect(context.responsive(phone: 1, desktop: 3), 1);
      expect(context.responsive(phone: 1, tablet: 2, desktop: 3), 2);
    });

    testWidgets('page inset opens up past a phone', (tester) async {
      // Read straight after each pump: pumpWidget reuses the element tree, so
      // holding on to the first context would just re-read the second size.
      final phoneInset =
          (await pumpAt(tester, _phone, const SizedBox())).pageInset;
      final tabletInset =
          (await pumpAt(tester, _tabletPortrait, const SizedBox())).pageInset;
      expect(tabletInset, greaterThan(phoneInset));
    });
  });

  group('ContentWidth', () {
    testWidgets('leaves a phone alone but caps a tablet', (tester) async {
      const key = Key('body');

      await pumpAt(
        tester,
        _phone,
        const ContentWidth(child: SizedBox.expand(key: key)),
      );
      // Nothing to give back on a phone — the column already fits.
      expect(tester.getSize(find.byKey(key)).width, _phone.width);

      await pumpAt(
        tester,
        _tabletPortrait,
        const ContentWidth(child: SizedBox.expand(key: key)),
      );
      final width = tester.getSize(find.byKey(key)).width;
      expect(width, lessThan(_tabletPortrait.width));
      expect(width, lessThanOrEqualTo(900));
    });

    testWidgets('narrow caps harder than wide', (tester) async {
      const key = Key('body');

      await pumpAt(
        tester,
        _tabletLandscape,
        const ContentWidth.narrow(child: SizedBox.expand(key: key)),
      );
      final narrow = tester.getSize(find.byKey(key)).width;

      await pumpAt(
        tester,
        _tabletLandscape,
        const ContentWidth.wide(child: SizedBox.expand(key: key)),
      );
      final wide = tester.getSize(find.byKey(key)).width;

      expect(narrow, lessThan(wide));
    });

    testWidgets('centres what it caps', (tester) async {
      const key = Key('body');
      await pumpAt(
        tester,
        _tabletLandscape,
        const ContentWidth(child: SizedBox.expand(key: key)),
      );
      final box = tester.getRect(find.byKey(key));
      final leftGap = box.left;
      final rightGap = _tabletLandscape.width - box.right;
      expect(leftGap, closeTo(rightGap, 0.5));
      expect(leftGap, greaterThan(0));
    });
  });

  group('ResponsiveGrid', () {
    Widget grid() => ResponsiveGrid(
      minItemWidth: 300,
      spacing: 0,
      children: List.generate(
        4,
        (i) => SizedBox(key: Key('item$i'), height: 10),
      ),
    );

    testWidgets('stacks one per row when only one column fits', (
      tester,
    ) async {
      await pumpAt(tester, _phone, grid());
      final first = tester.getRect(find.byKey(const Key('item0')));
      final second = tester.getRect(find.byKey(const Key('item1')));
      expect(second.top, greaterThan(first.top));
      expect(first.width, closeTo(_phone.width, 0.5));
    });

    testWidgets('shares a row once the width affords a second column', (
      tester,
    ) async {
      await pumpAt(tester, _tabletPortrait, grid());
      final first = tester.getRect(find.byKey(const Key('item0')));
      final second = tester.getRect(find.byKey(const Key('item1')));
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.left));
      // 834 / 300 -> 2 columns.
      expect(first.width, closeTo(_tabletPortrait.width / 2, 0.5));
    });

    testWidgets('never exceeds maxColumns', (tester) async {
      await pumpAt(
        tester,
        const Size(4000, 900),
        ResponsiveGrid(
          minItemWidth: 100,
          maxColumns: 3,
          spacing: 0,
          children: List.generate(
            3,
            (i) => SizedBox(key: Key('item$i'), height: 10),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('item0'))).width,
          closeTo(4000 / 3, 0.5));
    });

    testWidgets('an empty grid takes no space', (tester) async {
      await pumpAt(
        tester,
        _tabletPortrait,
        const ResponsiveGrid(minItemWidth: 300, children: []),
      );
      expect(find.byType(Wrap), findsNothing);
    });
  });
}
