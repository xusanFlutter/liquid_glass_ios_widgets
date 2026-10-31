import 'dart:async';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' show CupertinoTheme;
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
/// Parameters are resent whenever [creationParams] or the theme brightness
/// changes, and native events are routed to [handleEvent].
///
/// The native view follows the Flutter theme's brightness rather than the
/// iOS system appearance, so it matches apps that pick their own theme mode.
///
/// While the enclosing route is covered or animating (a push, a pop, a back
/// swipe), the native view is replaced by a pixel snapshot of itself. Moving
/// a platform view every frame forces Flutter to re-composite it with extra
/// overlay layers, which is what makes route transitions stutter; a snapshot
/// is an ordinary Flutter image and animates at full frame rate.
mixin NativeGlassViewMixin<T extends StatefulWidget> on State<T> {
  /// Last measured size per view type and parameters, so a new instance
  /// (e.g. the same tab bar on a freshly pushed page) starts at its real size
  /// instead of jumping once the native view reports it.
  static final _measuredSizes = <String, Size>{};

  MethodChannel? _channel;
  Map<String, Object?>? _sentParams;
  Brightness? _brightness;

  ModalRoute<Object?>? _route;
  bool _routeWasIdle = false;
  bool _capturingSnapshot = false;
  ui.Image? _snapshot;

  /// Size measured natively, used when the widget has no explicit size.
  Size? intrinsicSize;

  String get _sizeKey => '$viewType:${_paramsEquality.hash(creationParams)}';

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
    final params = _nativeParams;
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

  /// [creationParams] plus the parameters shared by every native view.
  Map<String, Object?> get _nativeParams => {
    ...creationParams,
    'brightness': _brightness?.name,
  };

  @override
  void initState() {
    super.initState();
    intrinsicSize = _measuredSizes[_sizeKey];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also registers a dependency, so theme changes call this again.
    _brightness = CupertinoTheme.brightnessOf(context);
    // Likewise for the route becoming (or ceasing to be) the current one.
    _watchRoute(ModalRoute.of(context));
    _updateFrozen();
    syncNativeView();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncNativeView();
  }

  @override
  void dispose() {
    _watchRoute(null);
    _channel?.setMethodCallHandler(null);
    _snapshot?.dispose();
    super.dispose();
  }

  Widget buildNativeView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
    PlatformViewHitTestBehavior hitTestBehavior =
        PlatformViewHitTestBehavior.opaque,
  }) {
    final params = _nativeParams;
    final snapshot = _snapshot;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Offstage keeps the native view (and its state) alive while it's
        // hidden, it just isn't composited.
        Offstage(
          offstage: snapshot != null,
          child: UiKitView(
            viewType: 'liquid_glass_ios_widgets/$viewType',
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            gestureRecognizers: gestureRecognizers,
            hitTestBehavior: hitTestBehavior,
            onPlatformViewCreated: (id) => _onPlatformViewCreated(id, params),
          ),
        ),
        if (snapshot != null)
          IgnorePointer(
            child: RawImage(image: snapshot, fit: BoxFit.fill),
          ),
      ],
    );
  }

  void _watchRoute(ModalRoute<Object?>? route) {
    if (route == _route) return;
    _route?.animation?.removeStatusListener(_onRouteAnimationStatus);
    _route?.secondaryAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _route = route;
    route?.animation?.addStatusListener(_onRouteAnimationStatus);
    route?.secondaryAnimation?.addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (mounted) _updateFrozen();
  }

  /// Whether the route is on top and not animating.
  bool get _routeIsIdle {
    final route = _route;
    if (route == null) return true;
    final animation = route.animation;
    final secondary = route.secondaryAnimation;
    return route.isCurrent &&
        (animation == null || animation.isCompleted) &&
        (secondary == null || secondary.isDismissed);
  }

  /// Switches between the live native view and its snapshot.
  void _updateFrozen() {
    if (_routeIsIdle) {
      _routeWasIdle = true;
      final snapshot = _snapshot;
      if (snapshot != null) {
        setState(() => _snapshot = null);
        // Dispose once the native view is back on screen.
        WidgetsBinding.instance.addPostFrameCallback((_) => snapshot.dispose());
      }
    } else if (_routeWasIdle && _snapshot == null) {
      // A page still animating in has never been shown idle, so there is
      // nothing worth snapshotting yet; it stays live.
      unawaited(_captureSnapshot());
    }
  }

  Future<void> _captureSnapshot() async {
    final channel = _channel;
    if (channel == null || _capturingSnapshot) return;
    _capturingSnapshot = true;
    try {
      final result = await channel.invokeMapMethod<String, Object?>('snapshot');
      if (result == null || !mounted || _routeIsIdle || _snapshot != null) {
        return;
      }
      final image = await _decodePixels(result);
      if (!mounted || _routeIsIdle || _snapshot != null) {
        image.dispose();
        return;
      }
      setState(() => _snapshot = image);
    } on PlatformException {
      // No snapshot: the native view simply stays live.
    } finally {
      _capturingSnapshot = false;
    }
  }

  static Future<ui.Image> _decodePixels(Map<String, Object?> result) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      result['pixels']! as Uint8List,
      result['width']! as int,
      result['height']! as int,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
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
      _measuredSizes[_sizeKey] = newSize;
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
