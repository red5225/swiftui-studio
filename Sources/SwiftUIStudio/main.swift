import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct SwiftUIStudioApp: App {
    var body: some Scene {
        WindowGroup {
            StudioWindow().frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") { NotificationCenter.default.post(name: .studioNew, object: nil) }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .saveItem) {
                Button("Open…") { NotificationCenter.default.post(name: .studioOpen, object: nil) }
                    .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let studioNew = Notification.Name("StudioNewDocument")
    static let studioOpen = Notification.Name("StudioOpenDocument")
}

struct StudioWindow: View {
    @State private var source = """
    import SwiftUI

    struct ContentView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundColor(.orange)
                Text("Hello, SwiftUI!")
                    .font(.largeTitle.bold())
                Text("Your interface, live.")
                    .foregroundColor(.secondary)
                Button("Get Started") { }
                    .buttonStyle(.borderedProminent)
            }
            .padding(32)
        }
    }
    """
    @State private var fileURL: URL?
    @State private var showPreview = true
    @State private var previewScale: Double = 1
    @State private var status = "Ready"
    @State private var refreshToken = UUID()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                editorPane
                if showPreview {
                    Divider()
                    previewPane
                }
            }
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .studioNew)) { _ in newDocument() }
        .onReceive(NotificationCenter.default.publisher(for: .studioOpen)) { _ in openDocument() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "swift").font(.system(size: 22, weight: .semibold)).foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(fileURL?.lastPathComponent ?? "Untitled.swift").font(.system(size: 13, weight: .semibold))
                Text("SWIFTUI STUDIO").font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.5).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: openDocument) { Label("Open", systemImage: "folder") }.buttonStyle(.bordered).help("Open a Swift file")
            Button(action: saveDocument) { Label("Save", systemImage: "square.and.arrow.down") }.buttonStyle(.bordered).help("Save source")
            Button { withAnimation(.easeInOut(duration: 0.2)) { showPreview.toggle() } } label: {
                Label(showPreview ? "Hide Preview" : "Show Preview", systemImage: "rectangle.split.2x1")
            }.buttonStyle(.bordered)
            Button { refreshToken = UUID(); status = "Preview refreshed" } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.bordered).help("Refresh preview")
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var editorPane: some View {
        VStack(spacing: 0) {
            HStack {
                Label("SOURCE", systemImage: "chevron.left.forwardslash.chevron.right").font(.system(size: 10, weight: .bold)).tracking(1)
                Spacer()
                Text("Swift").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 11).background(Color(nsColor: .underPageBackgroundColor))
            TextEditor(text: $source)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(Color(red: 0.84, green: 0.88, blue: 0.94))
                .scrollContentBackground(.hidden).padding(10)
                .background(Color(red: 0.075, green: 0.085, blue: 0.11))
                .onChange(of: source) { _ in status = "Edited · preview updates automatically" }
        }
        .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewPane: some View {
        VStack(spacing: 0) {
            HStack {
                Label("LIVE PREVIEW", systemImage: "eye").font(.system(size: 10, weight: .bold)).tracking(1)
                Spacer()
                Text("macOS").font(.system(size: 10, weight: .medium)).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
                Menu {
                    Button("50%") { previewScale = 0.5 }
                    Button("75%") { previewScale = 0.75 }
                    Button("100%") { previewScale = 1 }
                } label: { Image(systemName: "viewfinder") }.menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16).padding(.vertical, 11).background(Color(nsColor: .underPageBackgroundColor))
            ZStack {
                Color(red: 0.105, green: 0.115, blue: 0.14)
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(red: 1, green: 0.36, blue: 0.33)).frame(width: 8, height: 8)
                        Circle().fill(Color(red: 1, green: 0.74, blue: 0.25)).frame(width: 8, height: 8)
                        Circle().fill(Color(red: 0.18, green: 0.78, blue: 0.36)).frame(width: 8, height: 8)
                        Spacer()
                        Text("ContentView").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9).background(Color(red: 0.14, green: 0.15, blue: 0.18))
                    PreviewCanvas(source: source, refreshToken: refreshToken)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: .textBackgroundColor)).scaleEffect(previewScale).clipped().padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1)).padding(22)
            }
        }
        .frame(minWidth: 330, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.green).frame(width: 6, height: 6)
            Text(status).lineLimit(1)
            Spacer()
            Text("SwiftUI · macOS 12+").foregroundColor(.secondary)
            Text("UTF-8").foregroundColor(.secondary)
        }
        .font(.system(size: 10, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func newDocument() {
        source = "import SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        VStack {\n            Text(\"Hello, SwiftUI!\")\n                .font(.largeTitle)\n            Button(\"Tap Me\") { }\n        }\n        .padding()\n    }\n}\n"
        fileURL = nil
        status = "New document"
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.swiftSource, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            do { source = try String(contentsOf: url, encoding: .utf8); fileURL = url; status = "Opened \(url.lastPathComponent)" }
            catch { status = "Could not open file: \(error.localizedDescription)" }
        }
    }

    private func saveDocument() {
        let url: URL
        if let existing = fileURL { url = existing }
        else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.swiftSource]
            panel.nameFieldStringValue = "ContentView.swift"
            guard panel.runModal() == .OK, let picked = panel.url else { return }
            url = picked; fileURL = picked
        }
        do { try source.write(to: url, atomically: true, encoding: .utf8); status = "Saved \(url.lastPathComponent)" }
        catch { status = "Could not save file: \(error.localizedDescription)" }
    }
}

struct PreviewCanvas: View {
    let source: String
    let refreshToken: UUID

    private func firstCapture(_ pattern: String) -> String? {
        guard let range = source.range(of: pattern, options: .regularExpression),
              let quoted = source[range].range(of: #""([^"
]*)""#, options: .regularExpression) else { return nil }
        return String(source[range][quoted].dropFirst().dropLast())
    }

    private var displayText: String {
        firstCapture(#"Text\s*\(\s*"([^"
]*)"\s*\)"#) ?? (source.contains("ContentView") ? "Your SwiftUI view" : "Start building your view")
    }
    private var buttonTitle: String? { firstCapture(#"Button\s*\(\s*"([^"
]*)""#) }
    private var symbolName: String? { firstCapture(#"Image\s*\(\s*systemName:\s*"([^"
]*)""#) }

    var body: some View {
        VStack(spacing: 18) {
            if let symbolName = symbolName {
                Image(systemName: symbolName).font(.system(size: 42)).foregroundColor(.orange)
            }
            Text(displayText)
                .font(source.contains(".largeTitle") ? .largeTitle : .title2)
                .fontWeight(source.contains(".bold") ? .bold : .regular)
                .multilineTextAlignment(.center)
            if source.contains("foregroundColor(.secondary)") || source.contains("foregroundStyle(.secondary)") {
                Text("Your interface, live.").font(.subheadline).foregroundColor(.secondary)
            }
            if let title = buttonTitle {
                if source.contains("borderedProminent") {
                    Button(title) { }.buttonStyle(.borderedProminent)
                } else {
                    Button(title) { }.buttonStyle(.bordered)
                }
            }
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity).id(refreshToken)
    }
}
