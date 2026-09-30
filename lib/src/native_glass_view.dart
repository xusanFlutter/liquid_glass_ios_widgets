import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _paramsEquality = DeepCollectionEquality();

/// Whether native Liquid Glass platform views can be shown on this platform.
///
/// On every other platform the widgets render a Cupertino fallback.
bool get isNativeGlassPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Shared plumbing for widgets backed by a native iOS platform view.
///
/// Each view gets its own `liquid_glass_ios_widgets/view_<id>` channel.
/// Parameters are resent whenever [creationParams] changes, and native
/// events are routed to [handleEvent].
mixin NativeGlassViewMixin<T extends StatefulWidget> on State<T> {
  MethodChannel? _channel;
  Map<String, Object?>? _sentParams;

  /// Size measured natively, used when the widget has no explicit size.
  Size? intrinsicSize;

  /// View type suffix registered on the iOS side, e.g. `button`.
  String get viewType;

  /// Complete parameter map describing the native view.
  Map<String, Object?> get creationParams;

  /// Called for every event sent by the native view.
  void handleEvent(String method, Object? arguments) {}

  /// Sends the current [creationParams] to the native view.
  ///
  /// With [force], parameters are sent even if unchanged. Controlled widgets
  /// use it to revert native state when the parent rejects a change.
  void syncNativeView({bool force = false}) {
    final channel = _channel;
    if (channel == null) return;
    final params = creationParams;
    if (!force && _paramsEquality.equals(params, _sentParams)) return;
    _sentParams = params;
    channel.invokeMethod<void>('update', params);
  }

  /// Re-syncs after the parent had a chance to rebuild with the new value.
  void resyncAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) syncNativeView(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncNativeView();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  Widget buildNativeView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
    PlatformViewHitTestBehavior hitTestBehavior =
        PlatformViewHitTestBehavior.opaque,
  }) {
    final params = creationParams;
    return UiKitView(
      viewType: 'liquid_glass_ios_widgets/$viewType',
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: gestureRecognizers,
      hitTestBehavior: hitTestBehavior,
      onPlatformViewCreated: (id) => _onPlatformViewCreated(id, params),
    );
  }

  void _onPlatformViewCreated(int id, Map<String, Object?> params) {
    if (!mounted) return;
    _sentParams = params;
    _channel = MethodChannel('liquid_glass_ios_widgets/view_$id')
      ..setMethodCallHandler(_onNativeCall);
    // Parameters may have changed while the view was being created.
    syncNativeView();
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (!mounted) return null;
    if (call.method == 'intrinsicSize') {
      final size = call.arguments as Map<Object?, Object?>;
      final newSize = Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      );
      if (newSize != intrinsicSize) setState(() => intrinsicSize = newSize);
      return null;
    }
    handleEvent(call.method, call.arguments);
    return null;
  }
}

/// Lets horizontal drags and taps reach the native view even inside vertical
/// scrollables.
///
/// The tap recognizer is required: if every recognizer in the set rejects a
/// gesture (a drag recognizer rejects a plain tap), the platform view loses
/// the arena and never receives the touch.
final horizontalDragRecognizers = <Factory<OneSequenceGestureRecognizer>>{
  Factory<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new),
  Factory<TapGestureRecognizer>(TapGestureRecognizer.new),
};
