import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'native_glass_view.dart';
import 'types.dart';

/// A native Liquid Glass surface (`.glassEffect()`) with a Flutter [child]
/// drawn on top of it.
///
/// The glass refracts whatever Flutter renders behind it. Sized by [child]
/// (plus [padding]) unless [width] / [height] are given.
class LiquidGlassContainer extends StatefulWidget {
  const LiquidGlassContainer({
    super.key,
    this.child,
    this.shape = const LiquidGlassShape.rect(),
    this.variant = LiquidGlassVariant.regular,
    this.tint,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget? child;
  final LiquidGlassShape shape;
  final LiquidGlassVariant variant;

  /// Tints the glass. Use a translucent color for a subtle effect.
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  /// When set, the glass becomes interactive: it reacts to touches with the
  /// native press/shimmer effect and reports taps not handled by [child].
  final VoidCallback? onTap;

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with NativeGlassViewMixin {
  @override
  String get viewType => 'container';

  @override
  Map<String, Object?> get creationParams => {
    'shape': widget.shape.kind,
    'cornerRadius': widget.shape.cornerRadius,
    'variant': widget.variant.name,
    'tint': widget.tint?.toARGB32(),
    'interactive': widget.onTap != null,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    if (method == 'onTap') widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final glass = isNativeGlassPlatform
        ? buildNativeView(
            hitTestBehavior: widget.onTap != null
                ? PlatformViewHitTestBehavior.opaque
                : PlatformViewHitTestBehavior.transparent,
          )
        : _fallbackGlass();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: glass),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );
  }

  Widget _fallbackGlass() {
    final radius = switch (widget.shape.kind) {
      'rect' => BorderRadius.circular(widget.shape.cornerRadius ?? 16),
      _ => BorderRadius.circular(999),
    };
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ColoredBox(color: widget.tint ?? const Color(0x33FFFFFF)),
        ),
      ),
    );
  }
}
