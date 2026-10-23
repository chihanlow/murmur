import AppKit
import SwiftUI

/// The small pill at the bottom of the screen while dictating. It never takes focus.
@MainActor
final class HUD {
    enum Phase { case listening, transcribing, cleaning }

    final class Model: ObservableObject {
        @Published var phase: Phase = .listening
        @Published var levels: [CGFloat] = Array(repeating: 0, count: 9)
    }

    private let model = Model()
    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 44),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered, defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: PillView(model: model))
        return panel
    }()

    func show(_ phase: Phase) {
        model.phase = phase
        if phase == .listening { model.levels = Array(repeating: 0, count: model.levels.count) }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.minY + 28))
        }
        panel.orderFrontRegardless()
    }

    func push(level: Float) {
        model.levels.removeFirst()
        model.levels.append(CGFloat(level))
    }

    func hide() { panel.orderOut(nil) }
}

private struct PillView: View {
    @ObservedObject var model: HUD.Model

    var body: some View {
        HStack(spacing: 10) {
            switch model.phase {
            case .listening:
                Circle().fill(Color(red: 1, green: 0.27, blue: 0.3)).frame(width: 8, height: 8)
                HStack(spacing: 3) {
                    ForEach(model.levels.indices, id: \.self) { i in
                        Capsule()
                            .fill(.white)
                            .frame(width: 3, height: 4 + model.levels[i] * 18)
                    }
                }
                .animation(.easeOut(duration: 0.08), value: model.levels)
            case .transcribing, .cleaning:
                ProgressView().controlSize(.small).tint(.white)
                Text(model.phase == .cleaning ? "Cleaning up" : "Transcribing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(width: 180, height: 44)
        .background(Capsule().fill(Color.black.opacity(0.82)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
    }
}
