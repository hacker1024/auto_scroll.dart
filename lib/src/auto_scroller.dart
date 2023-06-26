import 'package:auto_scroll/src/auto_scroll_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resize_observer/flutter_resize_observer.dart';

/// A function that builds a scrolling widget, using the provided
/// [controller].
typedef AutoScrollWidgetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

class AutoScroller<T> extends StatefulWidget {
  /// The default value used for [duration].
  static const defaultDuration = Duration(milliseconds: 300);

  /// The default value used for [curve].
  static const defaultCurve = Curves.decelerate;

  /// An optional custom [AutoScrollController] to use.
  final AutoScrollController? controller;

  /// The axis that the child scrolls in.
  final Axis scrollAxis;

  /// An identifier representing the current length of the [ScrollView].
  ///
  /// This value must change whenever the length of the [ScrollView] changes.
  /// When it changes, the [ScrollView] will scroll to the bottom if it is
  /// considered anchored (see: [anchorThreshold]).
  ///
  /// Typically, this value would be the item count. If the size of items is
  /// variable, however, this value may need to be something else.
  final T lengthIdentifier;

  /// The duration of the scroll-to-bottom animation.
  final Duration duration;

  /// The curve of the scroll-to-bottom animation.
  final Curve curve;

  /// The distance from the bottom of the [ScrollView] that results in it being
  /// considered as anchored to the bottom.
  ///
  /// Changes to this value may only take effect once the [ScrollView] is not
  /// anchored.
  ///
  /// Also see: [lengthIdentifier].
  final double anchorThreshold;

  /// True if the [ScrollView] should initially be anchored to the bottom.
  final bool startAnchored;

  /// A callback that builds the [ScrollView] that is being auto-scrolled.
  final AutoScrollWidgetBuilder builder;

  const AutoScroller({
    super.key,
    this.scrollAxis = Axis.vertical,
    this.controller,
    required this.lengthIdentifier,
    this.duration = defaultDuration,
    this.curve = defaultCurve,
    this.anchorThreshold = 0,
    this.startAnchored = true,
    required this.builder,
  });

  @override
  State<AutoScroller<T>> createState() => AutoScrollerState();
}

class AutoScrollerState<T> extends State<AutoScroller<T>> {
  late AutoScrollController _controller;

  void _setUpController() =>
      _controller = widget.controller ?? AutoScrollController();

  static double _validateMaxScrollExtent(double maxScrollExtent) {
    assert(maxScrollExtent.isFinite, 'ScrollView length is unbounded!');
    return maxScrollExtent;
  }

  @override
  void initState() {
    super.initState();
    _setUpController();
    if (widget.startAnchored) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _controller.jumpToAnchor());
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AutoScroller<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _setUpController();
    }

    final lengthChanged = widget.lengthIdentifier != oldWidget.lengthIdentifier;
    if (lengthChanged && _controller.anchored) {
      WidgetsBinding.instance.scheduleFrameCallback(
        (_) => _controller.animateToAnchor(
          duration: widget.duration,
          curve: widget.curve,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = widget.builder(context, _controller.scrollController);

    return ResizeObserver(
      onResized: (Size oldSize, Size newSize) {
        if (!_controller.anchored) return;

        final bool scrollDimensionChanged;
        switch (widget.scrollAxis) {
          case Axis.horizontal:
            scrollDimensionChanged = oldSize.width != newSize.width;
            break;
          case Axis.vertical:
            scrollDimensionChanged = oldSize.height != newSize.height;
            break;
        }

        if (scrollDimensionChanged) {
          WidgetsBinding.instance
              .scheduleFrameCallback((_) => _controller.jumpToAnchor());
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0 ||
              notification is! ScrollEndNotification) {
            return false;
          }

          _controller.anchored =
              _validateMaxScrollExtent(notification.metrics.maxScrollExtent) -
                      notification.metrics.pixels <=
                  widget.anchorThreshold;
          return true;
        },
        child: scrollView,
      ),
    );
  }
}
