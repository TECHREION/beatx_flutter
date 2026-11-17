import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../module/watch/presentation/widgets/video_mini_player.dart';
import 'floating_player.dart';

/// Shows the [FloatingPlayer] on every screen of the app.
///
/// The player lives above the navigator (see [MiniPlayerOverlay], installed
/// in `GetMaterialApp.builder`), so it stays put while screens are pushed and
/// popped. A screen can adjust it for itself:
///
/// * [MiniPlayerAnchor] wraps a bottom bar (tab bar, "Buy Now" bar, cart
///   total…) so the player floats just above it instead of covering it;
/// * [MiniPlayerHidden] hides the player on that screen (the full player, the
///   video player, the payment page, the splash).
///
/// The player also steps aside while a dialog or bottom sheet is open.
class MiniPlayerHost {
  MiniPlayerHost._();

  /// Add to `GetMaterialApp.navigatorObservers`.
  static final MiniPlayerRouteObserver observer = MiniPlayerRouteObserver();

  static final _hidden = <Route<dynamic>>{}.obs;
  static final _anchors = <Route<dynamic>, double>{}.obs;

  /// Screens register while they are being built or torn down, when the
  /// overlay cannot be asked to rebuild; such changes wait for the frame to
  /// finish.
  static void _whenIdle(VoidCallback change) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => change());
    } else {
      change();
    }
  }

  static void _setHidden(Route<dynamic> route, bool hidden) => _whenIdle(() {
    if (hidden) {
      _hidden.add(route);
    } else {
      _hidden.remove(route);
    }
  });

  static void _setAnchor(Route<dynamic> route, double? height) => _whenIdle(() {
    if (height == null) {
      _anchors.remove(route);
    } else if (_anchors[route] != height) {
      _anchors[route] = height;
    }
  });
}

/// Tracks the route on top of the app's navigator.
class MiniPlayerRouteObserver extends NavigatorObserver {
  final top = Rxn<Route<dynamic>>();

  /// The route actually on top, tracked synchronously; [top] follows it once
  /// the overlay may rebuild.
  Route<dynamic>? _current;

  void _set(Route<dynamic>? route) {
    _current = route;
    MiniPlayerHost._whenIdle(() => top.value = _current);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_current == route) _set(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_current == route) _set(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_current == oldRoute) _set(newRoute);
  }
}

/// Hides the floating player while this widget's screen is on top.
class MiniPlayerHidden extends StatefulWidget {
  const MiniPlayerHidden({super.key, required this.child});

  final Widget child;

  @override
  State<MiniPlayerHidden> createState() => _MiniPlayerHiddenState();
}

class _MiniPlayerHiddenState extends State<MiniPlayerHidden> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    if (_route != null) MiniPlayerHost._setHidden(_route!, false);
    _route = route;
    if (route != null) MiniPlayerHost._setHidden(route, true);
  }

  @override
  void dispose() {
    if (_route != null) MiniPlayerHost._setHidden(_route!, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Marks [child] as this screen's bottom bar: the floating player sits just
/// above it. The bar is measured after layout, so its height can change (or
/// be zero when the bar is hidden).
class MiniPlayerAnchor extends StatefulWidget {
  const MiniPlayerAnchor({super.key, required this.child});

  final Widget child;

  @override
  State<MiniPlayerAnchor> createState() => _MiniPlayerAnchorState();
}

class _MiniPlayerAnchorState extends State<MiniPlayerAnchor> {
  final _key = GlobalKey();
  Route<dynamic>? _route;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    _detach();
    _route = route;
    // The bar slides in with the route; measure again once it has settled.
    _animation = route?.animation?..addStatusListener(_onRouteAnimation);
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) _measure();
  }

  void _detach() {
    _animation?.removeStatusListener(_onRouteAnimation);
    _animation = null;
    if (_route != null) MiniPlayerHost._setAnchor(_route!, null);
  }

  /// Distance from the bar's top edge to the bottom of the screen.
  void _measure() {
    if (!mounted) return;
    final route = _route;
    final box = _key.currentContext?.findRenderObject();
    if (route == null || box is! RenderBox || !box.hasSize) return;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final top = box.localToGlobal(Offset.zero).dy;
    final fromBottom = box.size.height == 0
        ? 0.0
        : (screenHeight - top).clamp(0.0, screenHeight);
    MiniPlayerHost._setAnchor(route, fromBottom.roundToDouble());
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

/// Puts the floating player above the app's screens. Use as (or inside)
/// `GetMaterialApp.builder`.
class MiniPlayerOverlay extends StatelessWidget {
  const MiniPlayerOverlay({super.key, required this.child, this.player});

  final Widget child;

  /// Replaces the [FloatingPlayer] in tests.
  final Widget? player;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Obx(() {
          final route = MiniPlayerHost.observer.top.value;
          final anchor = route == null ? null : MiniPlayerHost._anchors[route];
          final visible =
              route != null &&
              route is! PopupRoute &&
              !MiniPlayerHost._hidden.contains(route);
          final bottom = anchor ?? 0;

          return Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            // Kept alive while hidden so a dismissal or playing state is not
            // reset by opening a dialog.
            child: Visibility(
              visible: visible,
              maintainState: true,
              child: SafeArea(
                top: false,
                // Above a bar the bar already clears the home indicator.
                bottom: bottom == 0,
                child: Material(
                  type: MaterialType.transparency,
                  child:
                      player ??
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A minimized video, then the audio pill.
                          VideoMiniPlayer(),
                          FloatingPlayer(),
                        ],
                      ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
