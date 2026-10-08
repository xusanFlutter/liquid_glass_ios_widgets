import Flutter
import SwiftUI
import UIKit

/// Sends events from a native view to its Dart widget.
final class GlassEventEmitter {
  fileprivate weak var channel: FlutterMethodChannel?

  func send(_ method: String, _ arguments: Any? = nil) {
    channel?.invokeMethod(method, arguments: arguments)
  }
}

/// State of a SwiftUI component, driven by parameters coming from Dart.
///
/// Dart always sends the complete parameter map, so `update(with:)` replaces
/// the whole state rather than patching it.
protocol GlassViewModel: ObservableObject {
  func update(with params: [String: Any])
}

/// A Flutter platform view that hosts a SwiftUI view inside a transparent
/// `UIHostingController`.
///
/// Every instance owns a `liquid_glass_ios_widgets/view_<id>` method channel:
/// - Dart -> iOS: `update(params)` to refresh the model.
/// - iOS -> Dart: component events plus `intrinsicSize({width, height})`,
///   which lets Dart size widgets that don't have an explicit size.
final class HostedGlassView<Model: GlassViewModel, Content: View>: NSObject, FlutterPlatformView {
  private let container = UIView()
  private let hosting: UIHostingController<GlassAppearanceRoot<Content>>
  private let appearance = GlassAppearance()
  private let channel: FlutterMethodChannel
  private let model: Model
  private let emitter = GlassEventEmitter()
  private var lastReportedSize: CGSize = .zero

  init(
    frame: CGRect,
    viewId: Int64,
    messenger: FlutterBinaryMessenger,
    params: [String: Any],
    model: Model,
    content: (Model, GlassEventEmitter) -> Content
  ) {
    self.model = model
    channel = FlutterMethodChannel(
      name: "liquid_glass_ios_widgets/view_\(viewId)",
      binaryMessenger: messenger
    )
    emitter.channel = channel
    hosting = UIHostingController(
      rootView: GlassAppearanceRoot(appearance: appearance, content: content(model, emitter))
    )
    super.init()

    container.frame = frame
    container.backgroundColor = .clear
    container.clipsToBounds = false

    hosting.view.backgroundColor = .clear
    hosting.view.frame = container.bounds
    hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    if #available(iOS 16.4, *) {
      hosting.safeAreaRegions = []
    }
    container.addSubview(hosting.view)
    applyInterfaceStyle(params)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "update":
        if let params = call.arguments as? [String: Any] {
          self.applyInterfaceStyle(params)
          self.model.update(with: params)
          self.scheduleSizeReport()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    scheduleSizeReport()
  }

  /// Makes the view follow the Flutter theme's brightness.
  ///
  /// The trait override covers UIKit-backed SwiftUI controls. SwiftUI itself
  /// gets the color scheme through its environment: the hosting controller
  /// isn't in a view controller hierarchy, so trait changes alone don't
  /// reliably reach it.
  private func applyInterfaceStyle(_ params: [String: Any]) {
    let style = UIUserInterfaceStyle(brightness: params)
    appearance.colorScheme = ColorScheme(style)
    hosting.overrideUserInterfaceStyle = style
    container.applyInterfaceStyle(from: params)
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    container
  }

  private func scheduleSizeReport() {
    DispatchQueue.main.async { [weak self] in
      self?.reportIntrinsicSize()
    }
  }

  private func reportIntrinsicSize() {
    let fitting = hosting.sizeThatFits(in: CGSize(width: 10_000, height: 10_000))
    let size = CGSize(width: ceil(fitting.width), height: ceil(fitting.height))
    guard size.width > 0, size.height > 0, size != lastReportedSize else { return }
    lastReportedSize = size
    emitter.send("intrinsicSize", ["width": size.width, "height": size.height])
  }
}

/// Color scheme from the Flutter theme; nil follows the system.
final class GlassAppearance: ObservableObject {
  @Published var colorScheme: ColorScheme?
}

/// Injects [GlassAppearance] into the SwiftUI environment.
struct GlassAppearanceRoot<Content: View>: View {
  @ObservedObject var appearance: GlassAppearance
  let content: Content

  var body: some View {
    // transformEnvironment keeps the view identity (and state) stable when
    // switching between an explicit and the system color scheme.
    content.transformEnvironment(\.colorScheme) { scheme in
      if let override = appearance.colorScheme {
        scheme = override
      }
    }
  }
}

/// Creates platform views for one Dart `viewType`.
final class GlassViewFactory: NSObject, FlutterPlatformViewFactory {
  typealias Builder = (CGRect, Int64, [String: Any], FlutterBinaryMessenger) -> FlutterPlatformView

  private let messenger: FlutterBinaryMessenger
  private let builder: Builder

  init(messenger: FlutterBinaryMessenger, builder: @escaping Builder) {
    self.messenger = messenger
    self.builder = builder
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    builder(frame, viewId, args as? [String: Any] ?? [:], messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

/// Convenience for registering a SwiftUI-backed component.
func hostedGlassFactory<Model: GlassViewModel, Content: View>(
  messenger: FlutterBinaryMessenger,
  model: @escaping ([String: Any]) -> Model,
  content: @escaping (Model, GlassEventEmitter) -> Content
) -> GlassViewFactory {
  GlassViewFactory(messenger: messenger) { frame, viewId, params, messenger in
    HostedGlassView(
      frame: frame,
      viewId: viewId,
      messenger: messenger,
      params: params,
      model: model(params),
      content: content
    )
  }
}
