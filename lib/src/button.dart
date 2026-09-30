import 'package:flutter/cupertino.dart';

import 'native_glass_view.dart';
import 'types.dart';

/// A native iOS Liquid Glass button (`Button` with `.glass` / `.glassProminent` style).
///
/// Without [width] / [height] the button sizes itself to its native content.
/// Give an explicit size (e.g. `width: double.infinity` inside a bounded
/// parent) to stretch the glass.
///
/// Icons are SF Symbols names, e.g. `'heart.fill'`.
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    this.label,
    this.systemImage,
    this.style = LiquidGlassButtonStyle.glass,
    this.tint,
    this.foregroundColor,
    this.shape = const LiquidGlassShape.capsule(),
    this.size = LiquidGlassControlSize.regular,
    this.iconSize,
    this.width,
    this.height,
  }) : assert(label != null || systemImage != null);

  /// A circular, icon-only glass button.
  const LiquidGlassButton.icon({
    super.key,
    required this.onPressed,
    required String this.systemImage,
    this.style = LiquidGlassButtonStyle.glass,
    this.tint,
    this.foregroundColor,
    this.size = LiquidGlassControlSize.regular,
    this.iconSize,
    double dimension = 48,
  }) : label = null,
       shape = const LiquidGlassShape.circle(),
       width = dimension,
       height = dimension;

  /// Called on tap. The button is disabled when null.
  final VoidCallback? onPressed;

  final String? label;

  /// SF Symbols name shown before (or instead of) [label].
  final String? systemImage;

  final LiquidGlassButtonStyle style;

  /// Glass tint. For [LiquidGlassButtonStyle.prominent] it's the fill color.
  final Color? tint;

  /// Color of the label and icon.
  final Color? foregroundColor;

  final LiquidGlassShape shape;
  final LiquidGlassControlSize size;
  final double? iconSize;
  final double? width;
  final double? height;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with NativeGlassViewMixin {
  @override
  String get viewType => 'button';

  @override
  Map<String, Object?> get creationParams => {
    'label': widget.label,
    'systemImage': widget.systemImage,
    'style': widget.style.name,
    'tint': widget.tint?.toARGB32(),
    'foregroundColor': widget.foregroundColor?.toARGB32(),
    'enabled': widget.onPressed != null,
    'shape': widget.shape.kind,
    'cornerRadius': widget.shape.cornerRadius,
    'size': widget.size.name,
    'iconSize': widget.iconSize,
    'expandWidth': widget.width != null,
    'expandHeight': widget.height != null,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    if (method == 'onPressed') widget.onPressed?.call();
  }

  Size get _estimatedSize {
    final height = switch (widget.size) {
      LiquidGlassControlSize.mini => 24.0,
      LiquidGlassControlSize.small => 30.0,
      LiquidGlassControlSize.regular => 36.0,
      LiquidGlassControlSize.large => 48.0,
      LiquidGlassControlSize.extraLarge => 56.0,
    };
    final text = (widget.label?.length ?? 0) * 9.0;
    final icon = widget.systemImage != null ? 24.0 : 0.0;
    return Size(text + icon + 32, height);
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeGlassPlatform) return _fallback();

    final measured = intrinsicSize ?? _estimatedSize;
    return SizedBox(
      width: widget.width ?? measured.width,
      height: widget.height ?? measured.height,
      child: buildNativeView(),
    );
  }

  Widget _fallback() {
    final child = widget.label != null
        ? Text(widget.label!)
        : const Icon(CupertinoIcons.circle);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.style == LiquidGlassButtonStyle.prominent
          ? CupertinoButton.filled(onPressed: widget.onPressed, child: child)
          : CupertinoButton.tinted(onPressed: widget.onPressed, child: child),
    );
  }
}
