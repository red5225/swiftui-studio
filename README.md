# SwiftUI Studio

A lightweight, native SwiftUI source editor for Intel Macs running macOS 12 Monterey or newer. Built with SwiftUI and AppKit; no Electron, Python runtime, or web editor.

## Features

- Native macOS window with a source editor and live preview side by side
- Open and save `.swift` files
- Preview canvas reacts to common SwiftUI source patterns such as `Text`, `Button`, and `Image(systemName:)`
- Toggle preview visibility and adjust preview scale
- Keyboard shortcuts for new and open documents
- GitHub Actions builds an Intel `x86_64` app targeting macOS 12.0
- Workflow artifacts include a `.zip` app bundle and a `.dmg` disk image

## Important preview limitation

The current preview is a lightweight visual approximation driven by common source patterns. It does **not** compile and execute arbitrary edited SwiftUI code inside the preview. The app bundle itself is compiled natively with Apple's Swift compiler. A future iteration can add an isolated preview-build process for actual compiled previews.

## Build locally

On a Mac with Xcode Command Line Tools installed:

```bash
mkdir -p "SwiftUI Studio.app/Contents/MacOS"
swiftc -O -target x86_64-apple-macosx12.0 \
  -framework SwiftUI -framework AppKit \
  Sources/SwiftUIStudio/main.swift \
  -o "SwiftUI Studio.app/Contents/MacOS/SwiftUIStudio"
```

Create `Contents/Info.plist` with the bundle metadata in `.github/workflows/build.yml`, or run the GitHub Actions workflow to receive a ready-made app bundle and DMG.

## GitHub Actions

- **Actions → Build SwiftUI Studio → Run workflow** builds artifacts from `main`.
- Download `SwiftUI-Studio-macOS-Intel.zip` or `SwiftUI-Studio-macOS-Intel.dmg` from the run's Artifacts section.
- Push a version tag such as `v1.0.0` to publish both files as GitHub Release assets.

The app is ad-hoc signed for testing and is not notarized. macOS may require Control-click → Open on first launch.

## Compatibility

- Intel Macs (`x86_64`)
- macOS 12 Monterey and newer

## License

MIT. See [LICENSE](LICENSE).
