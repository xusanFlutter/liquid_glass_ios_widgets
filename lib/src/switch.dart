import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'native_glass_view.dart';

/// A native iOS switch (`UISwitch`) with the Liquid Glass thumb.
///
/// Controlled: the parent must rebuild with the new [value] from [onChanged],
/// otherwise the native switch snaps back.
class LiquidGlassSwitch extends StatefulWidget {
  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;

  /// The switch is disabled when null.
  final ValueChanged<bool>? onChanged;

  /// Track color when on.
  final Color? activeColor;

  @override
  State<LiquidGlassSwitch> createState() => _LiquidGlassSwitchState();
}

class _LiquidGlassSwitchState extends State<LiquidGlassSwitch>
    with NativeGlassViewMixin {
  Offset? _pointerDownPosition;
  bool _nativeChangedSinceDown = false;

  @override
  String get viewType => 'switch';

  @override
  Map<String, Object?> get creationParams => {
    'value': widget.value,
    'tint': widget.activeColor?.toARGB32(),
    'enabled': widget.onChanged != null,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    if (method == 'onChanged') {
      _nativeChangedSinceDown = true;
      widget.onChanged?.call(arguments! as bool);
      resyncAfterFrame();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _nativeChangedSinceDown = false;
  }

  /// UIKit receives a platform view's touches only after Flutter's gesture
  /// arena has resolved. For a very quick tap the native switch sometimes
  /// drops the delayed touch, so a tap is also detected here: if the native
  /// side didn't report a change shortly after, the switch is toggled from
  /// Dart (and the native view animates to the new value).
  void _onPointerUp(PointerUpEvent event) {
    final down = _pointerDownPosition;
    _pointerDownPosition = null;
    if (down == null || (event.position - down).distance > kTouchSlop) return;
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      final onChanged = widget.onChanged;
      if (!mounted || _nativeChangedSinceDown || onChanged == null) return;
      onChanged(!widget.value);
      resyncAfterFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeGlassPlatform) {
      return CupertinoSwitch(
        value: widget.value,
        onChanged: widget.onChanged,
        activeTrackColor: widget.activeColor,
      );
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: SizedBox.fromSize(
        size: intrinsicSize ?? const Size(64, 28),
        child: buildNativeView(gestureRecognizers: horizontalDragRecognizers),
      ),
    );
  }
}
