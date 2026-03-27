# ClipboardSanitizer

ClipboardSanitizer is a small macOS menu bar app that cleans copied text before you paste it.

## Features

- Strip rich text formatting (keep plain text)
- Remove common tracking parameters from URLs
- Normalize whitespace for cleaner output
- Trigger cleanup instantly with global hotkey `⌘⇧V`

## How To Use

1. Run the app.
2. Copy text from any app.
3. Press `⌘⇧V`.
4. Paste the cleaned text anywhere.

You can also click the menu bar icon to view app status and features.

## Run The App

```bash
brew install xcodegen
xcodegen generate
open ClipboardSanitizer.xcodeproj
```

Then run the `ClipboardSanitizer` scheme in Xcode.

## Share With Friends

Build and package the app with:

```bash
scripts/package-release.sh
```

This creates:
- `build/artifacts/ClipboardSanitizer-macOS.dmg`
- `build/artifacts/ClipboardSanitizer-macOS.zip`

If you just want the app bundle or the latest ZIP export, check the `build/export` folder.

## Keyboard Maestro Option

If you do not want to run the full app, you can use:
- `ClipboardSanitizer.scpt`
- `clipboard-sanitizer.sh`

## Notes

- The menu bar app uses hotkey `⌘⇧V`
- Full Xcode is required for `xcodebuild`
- For smooth installs on other Macs, use Apple signing and notarization when your developer account is ready
