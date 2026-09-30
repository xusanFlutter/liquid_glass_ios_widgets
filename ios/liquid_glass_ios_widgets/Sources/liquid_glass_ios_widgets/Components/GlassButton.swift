import SwiftUI

final class GlassButtonModel: GlassViewModel {
  @Published var label: String?
  @Published var systemImage: String?
  @Published var prominent = false
  @Published var tint: Color?
  @Published var foregroundColor: Color?
  @Published var enabled = true
  @Published var shape = "capsule"
  @Published var cornerRadius: Double?
  @Published var controlSize: ControlSize = .regular
  @Published var iconSize: Double?
  @Published var expandWidth = false
  @Published var expandHeight = false

  init(params: [String: Any]) {
    update(with: params)
  }

  func update(with params: [String: Any]) {
    label = params.string("label")
    systemImage = params.string("systemImage")
    prominent = params.string("style") == "prominent"
    tint = params.color("tint")
    foregroundColor = params.color("foregroundColor")
    enabled = params.bool("enabled") ?? true
    shape = params.string("shape") ?? "capsule"
    cornerRadius = params.double("cornerRadius")
    controlSize = ControlSize(name: params.string("size"))
    iconSize = params.double("iconSize")
    expandWidth = params.bool("expandWidth") ?? false
    expandHeight = params.bool("expandHeight") ?? false
  }

  var borderShape: ButtonBorderShape {
    switch shape {
    case "circle":
      if #available(iOS 17.0, *) {
        return .circle
      }
      return .capsule
    case "rect":
      return .roundedRectangle(radius: cornerRadius ?? 12)
    default:
      return .capsule
    }
  }
}

struct GlassButtonView: View {
  @ObservedObject var model: GlassButtonModel
  let events: GlassEventEmitter

  var body: some View {
    Button {
      events.send("onPressed")
    } label: {
      label
        .optionalForeground(model.foregroundColor)
        .frame(
          maxWidth: model.expandWidth ? .infinity : nil,
          maxHeight: model.expandHeight ? .infinity : nil
        )
        .contentShape(Rectangle())
    }
    .glassButtonStyle(prominent: model.prominent)
    .buttonBorderShape(model.borderShape)
    .controlSize(model.controlSize)
    .optionalTint(model.tint)
    .disabled(!model.enabled)
  }

  @ViewBuilder
  private var label: some View {
    switch (model.label, model.systemImage) {
    case let (title?, symbol?):
      Label {
        Text(title)
      } icon: {
        icon(symbol)
      }
    case let (nil, symbol?):
      icon(symbol)
    case let (title?, nil):
      Text(title)
    default:
      EmptyView()
    }
  }

  @ViewBuilder
  private func icon(_ name: String) -> some View {
    if let size = model.iconSize {
      Image(systemName: name).font(.system(size: size))
    } else {
      Image(systemName: name)
    }
  }
}
