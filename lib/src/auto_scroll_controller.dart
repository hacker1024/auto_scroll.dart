import 'dart:async';

import 'package:auto_scroll/src/auto_scroller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A controller used to control an [AutoScroller] widget.
///
/// This controller implements the [Listenable] interface, and will notify
/// listeners when the value of [anchored] changes. It also implements the
/// [ValueListenable] interface, and can be used with [ValueListenableBuilder].
class AutoScrollController extends ChangeNotifier
    implements ValueListenable<bool> {
  final bool _customScrollController;

  /// An optional custom [ScrollController] to use.
  ///
  /// This controller must not be used with any other scrollable widgets.
  ///
  /// If an external controller is provided, it must also be externally
  /// disposed.
  final ScrollController scrollController;

  AutoScrollController({
    ScrollController? scrollController,
  })  : scrollController = scrollController ?? ScrollController(),
        _customScrollController = scrollController != null;

  /// See: [anchored].
  var _anchored = false;

  /// True if the [ScrollView] is considered anchored to the bottom.
  bool get anchored => _anchored;

  /// An alias of [anchored].
  @override
  bool get value => anchored;

  /// Manually anchor or un-anchor the [ScrollView].
  ///
  /// Note that this won't perform any immediate scrolling. To anchor the
  /// [ScrollView] and scroll it to the bottom, use [jumpToAnchor] or
  /// [animateToAnchor].
  set anchored(bool value) {
    if (_anchored != value) {
      _anchored = value;
      notifyListeners();
    }
  }

  static double _validateMaxScrollExtent(double maxScrollExtent) {
    assert(maxScrollExtent.isFinite, 'ScrollView length is unbounded!');
    return maxScrollExtent;
  }

  Future<void> _goToLazyAnchor(
    FutureOr<void> Function(double position) move,
  ) async {
    anchored = true;
    // https://stackoverflow.com/a/67561421
    while (true) {
      // Move to the largest possible scroll position.
      final targetPosition =
          _validateMaxScrollExtent(scrollController.position.maxScrollExtent);
      await move(targetPosition);

      // Wait for the frame to complete.
      await WidgetsBinding.instance.endOfFrame;

      // If the scroll controller client has detached during the scroll process,
      // abort.
      if (!scrollController.hasClients) return;

      // If the largest possible scroll position has remained the same, then
      // break.
      //
      // Also break if the current scroll position is not equal to the initial
      // target position, as this can occur if a new move function was called
      // during this move loop, invalidating it.
      final resultantPosition = scrollController.position.pixels;
      if (resultantPosition ==
              _validateMaxScrollExtent(
                scrollController.position.maxScrollExtent,
              ) ||
          resultantPosition != targetPosition) {
        break;
      }
    }
  }

  /// Anchor and jump the [ScrollView] to the bottom.
  Future<void> jumpToAnchor() =>
      _goToLazyAnchor(scrollController.position.jumpTo);

  /// Anchor and animate the [ScrollView] to the bottom.
  Future<void> animateToAnchor({
    Duration duration = AutoScroller.defaultDuration,
    Curve curve = AutoScroller.defaultCurve,
  }) =>
      _goToLazyAnchor(
        (position) => scrollController.position.animateTo(
          position,
          duration: duration,
          curve: curve,
        ),
      );

  @override
  void dispose() {
    if (!_customScrollController) scrollController.dispose();
    super.dispose();
  }
}
