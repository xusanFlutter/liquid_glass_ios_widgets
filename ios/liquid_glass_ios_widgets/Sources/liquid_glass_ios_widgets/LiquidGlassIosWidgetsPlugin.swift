import Flutter
import UIKit

public class LiquidGlassIosWidgetsPlugin: NSObject, FlutterPlugin {
  static let viewTypePrefix = "liquid_glass_ios_widgets/"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "liquid_glass_ios_widgets",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(LiquidGlassIosWidgetsPlugin(), channel: channel)

    let messenger = registrar.messenger()
    let factories: [String: FlutterPlatformViewFactory] = [
      "button": hostedGlassFactory(
        messenger: messenger,
        model: GlassButtonModel.init(params:),
        content: { GlassButtonView(model: $0, events: $1) }
      ),
      "switch": GlassViewFactory(messenger: messenger) { frame, viewId, params, messenger in
        GlassSwitchPlatformView(frame: frame, viewId: viewId, params: params, messenger: messenger)
      },
      "slider": hostedGlassFactory(
        messenger: messenger,
        model: GlassSliderModel.init(params:),
        content: { GlassSliderView(model: $0, events: $1) }
      ),
      "segmented_control": hostedGlassFactory(
        messenger: messenger,
        model: GlassSegmentedControlModel.init(params:),
        content: { GlassSegmentedControlView(model: $0, events: $1) }
      ),
      "container": hostedGlassFactory(
        messenger: messenger,
        model: GlassContainerModel.init(params:),
        content: { GlassContainerView(model: $0, events: $1) }
      ),
      "tab_bar": GlassViewFactory(messenger: messenger) { frame, viewId, params, messenger in
        GlassTabBarPlatformView(frame: frame, viewId: viewId, params: params, messenger: messenger)
      },
    ]
    for (name, factory) in factories {
      registrar.register(
        factory,
        withId: viewTypePrefix + name,
        gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager
      )
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLiquidGlassSupported":
      if #available(iOS 26.0, *) {
        result(true)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
