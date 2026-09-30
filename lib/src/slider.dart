import 'package:flutter/cupertino.dart';

import 'native_glass_view.dart';

/// A native iOS slider with the Liquid Glass thumb.
///
/// Expands to the available width. Controlled: rebuild with the new [value]
/// from [onChanged].
class LiquidGlassSlider extends StatefulWidget {
  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.activeColor,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0);

  final double value;

  /// The slider is disabled when null.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  /// Number of discrete steps. Continuous when null.
  final int? divisions;

  /// Color of the filled part of the track.
  final Color? activeColor;

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider>
    with NativeGlassViewMixin {
  @override
  String get viewType => 'slider';

  @override
  Map<String, Object?> get creationParams => {
    'value': widget.value,
    'min': widget.min,
    'max': widget.max,
    'step': widget.divisions == null
        ? null
        : (widget.max - widget.min) / widget.divisions!,
    'tint': widget.activeColor?.toARGB32(),
    'enabled': widget.onChanged != null,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    final value = (arguments! as num).toDouble();
    switch (method) {
      case 'onChanged':
        widget.onChanged?.call(value);
      case 'onChangeStart':
        widget.onChangeStart?.call(value);
      case 'onChangeEnd':
        widget.onChangeEnd?.call(value);
        resyncAfterFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeGlassPlatform) {
      return CupertinoSlider(
        value: widget.value,
        onChanged: widget.onChanged,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        activeColor: widget.activeColor,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: intrinsicSize?.height ?? 44,
      child: buildNativeView(gestureRecognizers: horizontalDragRecognizers),
    );
  }
}
