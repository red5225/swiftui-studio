import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct SwiftUIStudioApp: App {
    var body: some Scene {
        WindowGroup { StudioWindow().frame(minWidth: 980, minHeight: 640) }
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("New") { NotificationCenter.default.post(name: .studioNew, object: nil) }
                        .keyboardShortcut("n", modifiers: .command)
                }
                CommandGroup(replacing: .saveItem) {
                    Button("Open…") { NotificationCenter.default.post(name: .studioOpen, object: nil) }
                        .keyboardShortcut("o", modifiers: .command)
                    Button("Save") { NotificationCenter.default.post(name: .studioSave, object: nil) }
                        .keyboardShortcut("s", modifiers: .command)
                }
            }
    }
}
extension Notification.Name {
    static let studioNew = Notification.Name("StudioNew")
    static let studioOpen = Notification.Name("StudioOpen")
    static let studioSave = Notification.Name("StudioSave")
}

struct StudioWindow: View {
    @State private var source = Self.starter
    @State private var fileURL: URL?
    @State private var status = "Ready"
    @State private var output = "SwiftUI Studio compiler output\n\nCheck validates Swift syntax. Run Preview compiles and launches a real SwiftUI app."
    @State private var busy = false
    @State private var showOutput = true
    @State private var runningPreview: NSRunningApplication?
    @State private var fontSize = 13.0

    static let starter = """
    import SwiftUI

    struct ContentView: View {
        @State private var count = 0
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundStyle(.orange)
                Text("Hello, SwiftUI!")
                    .font(.largeTitle.bold())
                Text("This is a real compiled preview.")
                    .foregroundStyle(.secondary)
                Button("Tap count: \\(count)") { count += 1 }
                    .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .frame(minWidth: 420, minHeight: 320)
        }
    }
    """

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Label("SOURCE", systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 10, weight: .bold)).tracking(1)
                        Spacer()
                        Text("Swift").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        Button { fontSize = max(10, fontSize - 1) } label: { Image(systemName: "minus.magnifyingglass") }
                        Button { fontSize = min(24, fontSize + 1) } label: { Image(systemName: "plus.magnifyingglass") }
                    }.padding(12).background(Color(nsColor: .controlBackgroundColor))
                    Divider()
                    TextEditor(text: $source)
                        .font(.system(size: fontSize, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Color(red: 0.86, green: 0.89, blue: 0.95))
                        .padding(8)
                        .background(Color(red: 0.055, green: 0.065, blue: 0.085))
                        .disabled(busy)
                }.frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

                if showOutput {
                    Divider()
                    VStack(spacing: 0) {
                        HStack {
                            Label("BUILD OUTPUT", systemImage: "terminal")
                                .font(.system(size: 10, weight: .bold)).tracking(1)
                            Spacer()
                            Button { output = "" } label: { Image(systemName: "trash") }
                        }.padding(12).background(Color(nsColor: .controlBackgroundColor))
                        Divider()
                        ScrollView {
                            Text(output.isEmpty ? "No output yet." : output)
                                .font(.system(size: 11, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled).padding(12)
                        }
                    }.frame(minWidth: 270, idealWidth: 340, maxWidth: 460)
                }
            }
            Divider()
            HStack(spacing: 8) {
                Circle().fill(busy ? .orange : (status.lowercased().contains("failed") ? .red : .green))
                    .frame(width: 7, height: 7)
                Text(status).lineLimit(1)
                Spacer()
                Text("x86_64 • macOS 12+").foregroundStyle(.secondary)
                Text("UTF-8").foregroundStyle(.secondary)
            }.font(.system(size: 10, weight: .medium)).padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .studioNew)) { _ in newDocument() }
        .onReceive(NotificationCenter.default.publisher(for: .studioOpen)) { _ in openDocument() }
        .onReceive(NotificationCenter.default.publisher(for: .studioSave)) { _ in saveDocument() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "swift").font(.system(size: 25, weight: .semibold)).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(fileURL?.lastPathComponent ?? "Untitled.swift").font(.system(size: 13, weight: .semibold))
                Text("SWIFTUI STUDIO").font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: openDocument) { Label("Open", systemImage: "folder") }
            Button(action: saveDocument) { Label("Save", systemImage: "square.and.arrow.down") }
            Divider().frame(height: 22)
            Button(action: checkSource) { Label("Check", systemImage: "checkmark.circle") }.disabled(busy)
            Button(action: runPreview) { Label("Run Preview", systemImage: "play.fill") }
                .buttonStyle(.borderedProminent).tint(.orange).disabled(busy)
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Button(action: stopPreview) { Image(systemName: "stop.fill") }
                .disabled(runningPreview == nil).help("Stop preview")
            Button { showOutput.toggle() } label: { Image(systemName: "sidebar.right") }.help("Toggle output")
        }.buttonStyle(.bordered).padding(.horizontal, 15).padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
    }

    private func newDocument() {
        source = Self.starter; fileURL = nil; status = "New document"
        output = "Define ContentView: View, then press Run Preview."
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.swiftSource, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            source = try String(contentsOf: url, encoding: .utf8)
            fileURL = url; status = "Opened \(url.lastPathComponent)"; output = url.path
        } catch { status = "Error opening file"; output = error.localizedDescription }
    }

    private func saveDocument() {
        let destination: URL
        if let fileURL { destination = fileURL }
        else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.swiftSource]
            panel.nameFieldStringValue = "ContentView.swift"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            destination = url
        }
        do {
            try source.write(to: destination, atomically: true, encoding: .utf8)
            fileURL = destination; status = "Saved \(destination.lastPathComponent)"
        } catch { status = "Error saving file"; output = error.localizedDescription }
    }

    private func checkSource() { compile(run: false) }

    private func runPreview() {
        guard source.contains("struct ContentView") || source.contains("class ContentView") else {
            status = "Preview needs ContentView"
            output = "Define a type named ContentView conforming to SwiftUI View. Do not include an @main app declaration."
            return
        }
        compile(run: true)
    }

    private func compile(run: Bool) {
        guard !busy else { return }
        busy = true
        status = run ? "Compiling preview…" : "Checking Swift…"
        let code = source
        let savedURL = fileURL
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let work = fm.temporaryDirectory.appendingPathComponent("SwiftUIStudio-\(UUID().uuidString)", isDirectory: true)
            let bundle = work.appendingPathComponent("SwiftUIStudioPreview.app", isDirectory: true)
            let contents = bundle.appendingPathComponent("Contents", isDirectory: true)
            let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
            let sourceFile = work.appendingPathComponent("UserView.swift")
            let hostFile = work.appendingPathComponent("PreviewHost.swift")
            let executable = macOS.appendingPathComponent("SwiftUIStudioPreview")
            do {
                try fm.createDirectory(at: work, withIntermediateDirectories: true)
                try code.write(to: sourceFile, atomically: true, encoding: .utf8)
                let host = """
                import SwiftUI
                @main
                struct SwiftUIStudioPreviewHost: App {
                    var body: some Scene { WindowGroup { ContentView() } }
                }
                """
                if run {
                    try fm.createDirectory(at: macOS, withIntermediateDirectories: true)
                    try host.write(to: hostFile, atomically: true, encoding: .utf8)
                    let plist: [String: Any] = [
                        "CFBundleExecutable": "SwiftUIStudioPreview",
                        "CFBundleIdentifier": "com.red5225.swiftuistudio.preview",
                        "CFBundleName": "SwiftUI Studio Preview",
                        "CFBundlePackageType": "APPL",
                        "LSMinimumSystemVersion": "12.0",
                        "NSHighResolutionCapable": true
                    ]
                    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                    try data.write(to: contents.appendingPathComponent("Info.plist"))
                }
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
                process.arguments = run
                    ? ["swiftc", "-target", "x86_64-apple-macosx12.0", "-framework", "SwiftUI", sourceFile.path, hostFile.path, "-o", executable.path]
                    : ["swiftc", "-typecheck", "-target", "x86_64-apple-macosx12.0", "-framework", "SwiftUI", sourceFile.path]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                try process.run()
                let dataOut = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let ok = process.terminationStatus == 0
                var report = String(data: dataOut, encoding: .utf8) ?? ""
                if report.isEmpty { report = ok ? "Build succeeded with no compiler warnings." : "Compiler exited with code \(process.terminationStatus)." }
                if let savedURL { report = "Source: \(savedURL.path)\n\n" + report }
                if ok && run {
                    let semaphore = DispatchSemaphore(value: 0)
                    var launched: NSRunningApplication?
                    var launchFailure: Error?
                    DispatchQueue.main.async {
                        let config = NSWorkspace.OpenConfiguration()
                        config.activates = true
                        NSWorkspace.shared.openApplication(at: bundle, configuration: config) { app, error in
                            launched = app; launchFailure = error; semaphore.signal()
                        }
                    }
                    semaphore.wait()
                    if let launchFailure { throw launchFailure }
                    DispatchQueue.main.async {
                        self.runningPreview = launched
                        self.output = report + "\n\nLaunched compiled SwiftUI preview."
                        self.status = "Preview running"; self.busy = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.output = report
                        self.status = ok ? "Check passed" : "Build failed — see output"
                        self.busy = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.output = "Could not invoke Swift compiler. Install Xcode or Command Line Tools (xcode-select --install).\n\n\(error.localizedDescription)"
                    self.status = "Build failed"; self.busy = false
                }
            }
        }
    }

    private func stopPreview() {
        runningPreview?.terminate()
        runningPreview = nil
        status = "Preview stopped"
    }
}
