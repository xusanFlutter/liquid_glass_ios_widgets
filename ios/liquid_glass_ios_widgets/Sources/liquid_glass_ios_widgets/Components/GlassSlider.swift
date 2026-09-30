import SwiftUI

final class GlassSliderModel: GlassViewModel {
  @Published var value = 0.0
  @Published var min = 0.0
  @Published var max = 1.0
  @Published var step: Double?
  @Published var tint: Color?
  @Published var enabled = true

  /// While the user drags, values echoed back from Dart are stale and would
  /// make the thumb jitter, so they are ignored.
  var isEditing = false

  init(params: [String: Any]) {
    update(with: params)
  }

  func update(with params: [String: Any]) {
    let newMin = params.double("min") ?? 0
    let newMax = Swift.max(params.double("max") ?? 1, newMin + .ulpOfOne)
    min = newMin
    max = newMax
    step = params.double("step")
    tint = params.color("tint")
    enabled = params.bool("enabled") ?? true
    if !isEditing {
      value = Swift.min(Swift.max(params.double("value") ?? newMin, newMin), newMax)
    }
  }
}

/// A native `Slider`, which gets the Liquid Glass thumb on iOS 26.
struct GlassSliderView: View {
  @ObservedObject var model: GlassSliderModel
  let events: GlassEventEmitter

  var body: some View {
    slider
      .optionalTint(model.tint)
      .disabled(!model.enabled)
      .padding(.horizontal, 2)
  }

  @ViewBuilder
  private var slider: some View {
    if let step = model.step, step > 0 {
      Slider(value: binding, in: model.min...model.max, step: step, onEditingChanged: editingChanged)
    } else {
      Slider(value: binding, in: model.min...model.max, onEditingChanged: editingChanged)
    }
  }

  private var binding: Binding<Double> {
    Binding(
      get: { model.value },
      set: { newValue in
        guard newValue != model.value else { return }
        model.value = newValue
        events.send("onChanged", newValue)
      }
    )
  }

  private func editingChanged(_ editing: Bool) {
    model.isEditing = editing
    events.send(editing ? "onChangeStart" : "onChangeEnd", model.value)
  }
}
