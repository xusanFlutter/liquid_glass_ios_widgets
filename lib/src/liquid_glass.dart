import 'package:flutter/services.dart';

import 'native_glass_view.dart';

/// Plugin-level utilities.
abstract final class LiquidGlass {
  static const _channel = MethodChannel('liquid_glass_ios_widgets');

  /// Whether the device renders real Liquid Glass (iOS 26+).
  ///
  /// On older iOS versions the widgets still work, but fall back to native
  /// materials and bordered button styles. On other platforms, to Cupertino
  /// widgets.
  static Future<bool> isSupported() async {
    if (!isNativeGlassPlatform) return false;
    return await _channel.invokeMethod<bool>('isLiquidGlassSupported') ?? false;
  }
}
