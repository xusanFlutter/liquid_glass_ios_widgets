import SwiftUI

final class GlassContainerModel: GlassViewModel {
  @Published var variant: String?
  @Published var tint: Color?
  @Published var interactive = false
  @Published var shape = GlassShape(kind: nil, cornerRadius: nil)

  init(params: [String: Any]) {
    update(with: params)
  }

  func update(with params: [String: Any]) {
    variant = params.string("variant")
    tint = params.color("tint")
    interactive = params.bool("interactive") ?? false
    shape = GlassShape(kind: params.string("shape"), cornerRadius: params.double("cornerRadius"))
  }
}

/// A bare Liquid Glass surface. Flutter draws the container's child on top.
struct GlassContainerView: View {
  @ObservedObject var model: GlassContainerModel
  let events: GlassEventEmitter

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(model.shape)
      .liquidGlass(
        variant: model.variant,
        tint: model.tint,
        interactive: model.interactive,
        in: model.shape
      )
      .onTapGesture {
        if model.interactive {
          events.send("onTap")
        }
      }
  }
}
