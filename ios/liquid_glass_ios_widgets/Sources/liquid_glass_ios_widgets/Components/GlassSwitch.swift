import Flutter
import UIKit

/// A native `UISwitch`, which gets the Liquid Glass thumb on iOS 26.
///
/// UIKit is used directly since the control needs no SwiftUI layout, which
/// avoids a hosting controller per switch.
final class GlassSwitchPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()
  private let toggle = UISwitch()
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, params: [String: Any], messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "liquid_glass_ios_widgets/view_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    container.frame = frame
    container.backgroundColor = .clear
    toggle.translatesAutoresizingMaskIntoConstraints = false
    toggle.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    container.addSubview(toggle)
    NSLayoutConstraint.activate([
      toggle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    apply(params, animated: false)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "update":
        if let params = call.arguments as? [String: Any] {
          self.apply(params, animated: true)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let size = toggle.intrinsicContentSize
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod("intrinsicSize", arguments: ["width": size.width, "height": size.height])
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    container
  }

  private func apply(_ params: [String: Any], animated: Bool) {
    toggle.applyInterfaceStyle(from: params)
    toggle.onTintColor = params.uiColor("tint")
    toggle.isEnabled = params.bool("enabled") ?? true
    let value = params.bool("value") ?? false
    if toggle.isOn != value {
      toggle.setOn(value, animated: animated)
    }
  }

  @objc private func valueChanged() {
    channel.invokeMethod("onChanged", arguments: toggle.isOn)
  }
}
