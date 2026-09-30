import 'package:flutter/cupertino.dart';

import 'native_glass_view.dart';

/// One segment of a [LiquidGlassSegmentedControl]: a text label or an SF Symbol.
class LiquidGlassSegment {
  const LiquidGlassSegment({this.label, this.systemImage})
    : assert(label != null || systemImage != null);

  final String? label;

  /// SF Symbols name. Takes precedence over [label] when both are set.
  final String? systemImage;

  Map<String, Object?> toMap() => {'label': label, 'systemImage': systemImage};
}

/// A native iOS segmented control with the Liquid Glass selection indicator.
///
/// Controlled: rebuild with the new [selectedIndex] from [onChanged].
class LiquidGlassSegmentedControl extends StatefulWidget {
  const LiquidGlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.tint,
    this.expand = false,
  }) : assert(segments.length > 1);

  final List<LiquidGlassSegment> segments;
  final int selectedIndex;

  /// The control is disabled when null.
  final ValueChanged<int>? onChanged;
  final Color? tint;

  /// Stretch to the available width instead of hugging the segments.
  final bool expand;

  @override
  State<LiquidGlassSegmentedControl> createState() =>
      _LiquidGlassSegmentedControlState();
}

class _LiquidGlassSegmentedControlState
    extends State<LiquidGlassSegmentedControl>
    with NativeGlassViewMixin {
  @override
  String get viewType => 'segmented_control';

  @override
  Map<String, Object?> get creationParams => {
    'segments': [for (final segment in widget.segments) segment.toMap()],
    'selectedIndex': widget.selectedIndex,
    'tint': widget.tint?.toARGB32(),
    'enabled': widget.onChanged != null,
    'expand': widget.expand,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    if (method == 'onChanged') {
      widget.onChanged?.call(arguments! as int);
      resyncAfterFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeGlassPlatform) return _fallback();

    final size = intrinsicSize ?? Size(widget.segments.length * 80.0, 32);
    return SizedBox(
      width: widget.expand ? double.infinity : size.width,
      height: size.height,
      child: buildNativeView(),
    );
  }

  Widget _fallback() {
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: widget.selectedIndex,
      thumbColor: widget.tint ?? CupertinoColors.white,
      onValueChanged: (index) {
        if (index != null) widget.onChanged?.call(index);
      },
      children: {
        for (final (index, segment) in widget.segments.indexed)
          index: Text(segment.label ?? segment.systemImage!),
      },
    );
  }
}
