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
  private let hosting: UIHostingController<Content>
  private let channel: FlutterMethodChannel
  private let model: Model
  private let emitter = GlassEventEmitter()
  private var lastReportedSize: CGSize = .zero

  init(
    frame: CGRect,
    viewId: Int64,
    messenger: FlutterBinaryMessenger,
    model: Model,
    content: (Model, GlassEventEmitter) -> Content
  ) {
    self.model = model
    channel = FlutterMethodChannel(
      name: "liquid_glass_ios_widgets/view_\(viewId)",
      binaryMessenger: messenger
    )
    emitter.channel = channel
    hosting = UIHostingController(rootView: content(model, emitter))
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

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "update":
        if let params = call.arguments as? [String: Any] {
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
      model: model(params),
      content: content
    )
  }
}
