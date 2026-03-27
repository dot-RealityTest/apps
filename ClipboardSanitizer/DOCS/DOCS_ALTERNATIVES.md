# Documentation Copy Alternatives

## Marketing Version
ClipboardSanitizer gives you clean, paste-ready text in one shortcut.

Copy from anywhere, press `⌘⇧V`, and remove formatting noise, URL trackers, and messy spacing before sharing your text.

### Highlights
- Instant cleanup from the menu bar
- Privacy-friendly URL sanitization
- Better readability with whitespace normalization
- Zero workflow disruption

## Technical Version
ClipboardSanitizer is a macOS background utility that reads plain text from the system pasteboard, applies deterministic text transformations, and writes sanitized text back to the clipboard.

### Processing Pipeline
1. Read `NSPasteboard.general` content
2. Prefer `.string` text representation
3. Remove URL tracking query parameters (`utm_*`, `fbclid`, `gclid`, etc.)
4. Normalize whitespace
5. Write sanitized output back as plain text

### Runtime Behavior
- Menu bar app (`NSStatusItem`)
- Global hotkey: `⌘⇧V` (Carbon hotkey registration)
- Local notifications when ready and after sanitization

## App Store-Style Version
Clean clipboard text instantly.

ClipboardSanitizer is a simple menu bar app for macOS that helps you paste cleaner text everywhere. Use `⌘⇧V` to remove rich formatting, strip tracking parameters from links, and normalize spacing in seconds.

### Why You'll Like It
- Fast one-key cleanup
- Cleaner links for sharing
- Better-looking notes, emails, and docs
- Lightweight and always ready in the menu bar

## Reusable One-Liners
- Clean your clipboard before every paste.
- One shortcut to strip formatting and tracking links.
- Paste cleaner text with `⌘⇧V`.
- Menu bar utility for fast clipboard cleanup.
- Turn noisy copied text into paste-ready content instantly.
