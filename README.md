# SwiftUI Studio

A native SwiftUI source editor for Intel Macs running macOS 12 Monterey or newer.

## Features

- Native macOS source editor with open/save and keyboard shortcuts.
- Compiler-backed Swift type checking using the Mac's installed Swift compiler.
- Real compiled SwiftUI preview: compile a ContentView and launch it as a separate native app. Apple's SwiftUI framework renders the actual layout, state, animations, controls, and interactions.
- Compiler diagnostics and build output panel.
- Adjustable editor font, preview launch/stop controls, and dark editor styling.
- GitHub Actions builds an Intel app bundle, ZIP, and DMG.

## Real preview requirements

The preview compiles your source locally using xcrun swiftc. Install Xcode or Apple's Command Line Tools first. The source file must define a SwiftUI type named ContentView conforming to View. Do not add a second @main app declaration. This version compiles one source file plus a generated host; it is not yet a complete Xcode replacement for multi-target projects, asset catalogs, Swift Package Manager dependencies, or arbitrary app lifecycle configuration.

The app and preview target x86_64-apple-macosx12.0 for Intel Macs on Monterey and later.

## Downloads

Open [GitHub Actions](https://github.com/red5225/swiftui-studio/actions), select the latest successful Build SwiftUI Studio run, and download the SwiftUI-Studio-macOS-Intel artifact. A version tag such as v1.1.0 publishes the ZIP and DMG to GitHub Releases.

## Known limits

This is an early IDE foundation, not Xcode feature parity. The editor does not yet bundle SourceKit-LSP, full syntax highlighting, code completion, multi-file project management, a debugger, package manager UI, or simulator/device deployment. Swift language support depends on the Swift toolchain installed on the Mac.
