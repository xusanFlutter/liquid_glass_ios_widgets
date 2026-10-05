import 'package:flutter/widgets.dart';

import 'liquid_glass.dart';

/// Shows [glass] when the device supports Liquid Glass (iOS 26+) and
/// [fallback] otherwise.
///
/// ```dart
/// LiquidGlassAdaptive(
///   glass: LiquidGlassButton(label: 'Save', onPressed: save),
///   fallback: CupertinoButton.filled(onPressed: save, child: Text('Save')),
/// )
/// ```
///
/// See [LiquidGlass.isSupportLiquidGlass].
class LiquidGlassAdaptive extends StatelessWidget {
  const LiquidGlassAdaptive({
    super.key,
    required this.glass,
    required this.fallback,
  });

  /// Shown when Liquid Glass is supported.
  final Widget glass;

  /// Shown when Liquid Glass is not supported.
  final Widget fallback;

  @override
  Widget build(BuildContext context) =>
      LiquidGlass.isSupportLiquidGlass ? glass : fallback;
}
