import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_glass_view.dart';

/// Plugin-level utilities.
abstract final class LiquidGlass {
  static const _channel = MethodChannel('liquid_glass_ios_widgets');

  /// Overrides [isSupportLiquidGlass] in tests.
  @visibleForTesting
  static bool? debugIsSupportLiquidGlassOverride;

  static final bool _isSupportLiquidGlass = _detectSupport();

  /// Whether the device renders real Liquid Glass (iOS 26+).
  ///
  /// Synchronous, so it can be used directly in `build` methods. Derived from
  /// the iOS version reported by the OS; always false on other platforms.
  ///
  /// When it's false the widgets still work: on older iOS versions they fall
  /// back to native materials and bordered button styles, on other platforms
  /// to Cupertino widgets.
  static bool get isSupportLiquidGlass =>
      debugIsSupportLiquidGlassOverride ?? _isSupportLiquidGlass;

  /// Same as [isSupportLiquidGlass], but asks the native side.
  static Future<bool> isSupported() async {
    if (debugIsSupportLiquidGlassOverride case final override?) return override;
    if (!isNativeGlassPlatform) return false;
    return await _channel.invokeMethod<bool>('isLiquidGlassSupported') ?? false;
  }

  static bool _detectSupport() {
    if (!isNativeGlassPlatform) return false;
    final major = iosMajorVersion(Platform.operatingSystemVersion);
    return major != null && major >= 26;
  }

  /// Extracts the major version from an iOS version string such as
  /// `"Version 26.0 (Build 23A341)"` or `"26.0.1"`.
  @visibleForTesting
  static int? iosMajorVersion(String versionString) {
    final match = RegExp(r'(\d+)(?:\.\d+)+').firstMatch(versionString);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
