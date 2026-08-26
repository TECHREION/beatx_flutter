/// Layout helpers for making a phone-shaped app read well on a tablet.
///
/// Every screen here is built for one narrow column running edge to edge.
/// Stretched across a tablet that reads as a blown-up phone screenshot: lines
/// run far past a comfortable reading width, a 72pt thumbnail looks lost
/// against a metre of empty row, and a list of cards wastes most of the width
/// it was given.
///
/// Two moves fix most of it, and both live here:
///
///  * [ContentWidth] caps how wide a column of content may get and centres it,
///    so a wide screen gains margin rather than longer lines.
///  * [ResponsiveContext.columnsFor] turns a one-per-row list into as many
///    columns as the width actually affords.
library;

import 'package:flutter/material.dart';

/// Where the layout changes shape. 600 is the usual phone/tablet split; 1000
/// is where a tablet has room for two panes side by side.
enum FormFactor { phone, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final width = screenWidth;
    if (width >= 1000) return FormFactor.desktop;
    if (width >= 600) return FormFactor.tablet;
    return FormFactor.phone;
  }

  bool get isPhone => formFactor == FormFactor.phone;

  /// True on anything wider than a phone. Most layout choices only need this
  /// much — reach for [formFactor] when a third size genuinely differs.
  bool get isWide => formFactor != FormFactor.phone;

  /// True where there is room to put two panes beside each other, such as a
  /// video with its Up Next list alongside instead of beneath.
  bool get isSplitReady => formFactor == FormFactor.desktop;

  /// Picks a value for the current width, falling back to the next size down
  /// when one is not given.
  T responsive<T>({required T phone, T? tablet, T? desktop}) {
    switch (formFactor) {
      case FormFactor.desktop:
        return desktop ?? tablet ?? phone;
      case FormFactor.tablet:
        return tablet ?? phone;
      case FormFactor.phone:
        return phone;
    }
  }

  /// Horizontal inset for page content. A tablet can afford more breathing
  /// room at the edges than a phone.
  double get pageInset => responsive(phone: 16.0, tablet: 28.0, desktop: 40.0);

  /// How many columns a grid of cards at least [minItemWidth] wide should use
  /// across [available] (the page inset is assumed already removed).
  ///
  /// Driven by the width each card needs rather than by a breakpoint, so a
  /// grid keeps looking right at sizes nobody thought to test — a split-screen
  /// tablet, or a foldable part-way open.
  int columnsFor(double available, double minItemWidth, {int max = 4}) {
    if (minItemWidth <= 0) return 1;
    final fits = (available / minItemWidth).floor();
    return fits.clamp(1, max);
  }
}

/// Caps how wide its child may get and centres it.
///
/// This is the single biggest difference between a phone layout that has been
/// stretched and one that was meant for the screen: past roughly [maxWidth] a
/// column stops gaining anything from extra width and starts losing
/// readability, so the surplus becomes margin instead.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padded = true,
  });

  /// A media-heavy grid can justify going wider than a column of text.
  const ContentWidth.wide({super.key, required this.child, this.padded = true})
    : maxWidth = 1200;

  /// For a column that is mostly prose or list rows, where long lines hurt
  /// most — settings, details, forms.
  const ContentWidth.narrow({
    super.key,
    required this.child,
    this.padded = true,
  }) : maxWidth = 720;

  final Widget child;
  final double maxWidth;

  /// Whether to apply the page's horizontal inset. Off for content that
  /// already brings its own padding.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final inset = padded && context.isWide ? context.pageInset : 0.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: child,
        ),
      ),
    );
  }
}

/// Lays children out in as many columns as the width affords, one per row on a
/// phone.
///
/// Sized by [minItemWidth] rather than a fixed column count so the same call
/// works on a phone, a split-screen tablet and a full-width one.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.minItemWidth,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = context.columnsFor(
          constraints.maxWidth,
          minItemWidth,
          max: maxColumns,
        );
        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }

        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
