import SwiftUI

final class GlassSegmentedControlModel: GlassViewModel {
  struct Segment {
    let label: String?
    let systemImage: String?
  }

  @Published var segments: [Segment] = []
  @Published var selectedIndex = 0
  @Published var tint: Color?
  @Published var enabled = true
  @Published var expand = false

  init(params: [String: Any]) {
    update(with: params)
  }

  func update(with params: [String: Any]) {
    segments = params.maps("segments").map {
      Segment(label: $0.string("label"), systemImage: $0.string("systemImage"))
    }
    selectedIndex = params.int("selectedIndex") ?? 0
    tint = params.color("tint")
    enabled = params.bool("enabled") ?? true
    expand = params.bool("expand") ?? false
  }
}

/// A native segmented `Picker`, which gets the Liquid Glass selection on iOS 26.
struct GlassSegmentedControlView: View {
  @ObservedObject var model: GlassSegmentedControlModel
  let events: GlassEventEmitter

  var body: some View {
    let picker = Picker("", selection: selection) {
      ForEach(model.segments.indices, id: \.self) { index in
        segment(model.segments[index]).tag(index)
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .optionalTint(model.tint)
    .disabled(!model.enabled)

    if model.expand {
      picker
    } else {
      picker.fixedSize()
    }
  }

  private var selection: Binding<Int> {
    Binding(
      get: { model.selectedIndex },
      set: { newValue in
        guard newValue != model.selectedIndex else { return }
        model.selectedIndex = newValue
        events.send("onChanged", newValue)
      }
    )
  }

  @ViewBuilder
  private func segment(_ segment: GlassSegmentedControlModel.Segment) -> some View {
    if let symbol = segment.systemImage {
      Image(systemName: symbol)
    } else {
      Text(segment.label ?? "")
    }
  }
}
