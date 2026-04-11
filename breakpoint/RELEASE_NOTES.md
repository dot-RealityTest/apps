# BreakPoint Release Notes

## Version 1.0

BreakPoint is a notarized macOS menu bar utility for capturing a "Doom's Moment" before stepping away from work. It gathers current context, generates a structured handoff, and exports the result to Markdown files and optionally Apple Notes.

## Highlights

- Four generation modes:
  - `Normal`
  - `ADHD`
  - `Code Mode`
  - `Extra`
- Configurable export presets:
  - `File`
  - `Notes`
  - `File + Notes`
- Configurable Pieces OS base URL in `Properties`
- Ollama model dropdown with refresh support
- Custom search tags field that is merged into generated hashtags
- Faster generation fallback behavior:
  - Pieces QGPT fails fast if unavailable
  - Ollama fallback uses a longer timeout for large prompts
  - Ollama requests disable model "thinking" output to improve response speed
- Apple Notes export support with checklist formatting
- Global hotkey:
  - `Cmd + Shift + Escape`

## Distribution Artifact

Attach the notarized DMG from:

- `build/notarization/BreakPoint.dmg`

This DMG was:

- Developer ID signed
- notarized by Apple
- stapled successfully

## Setup Requirements

- macOS 14.0 or later
- Ollama installed and running
- Pieces OS running on the configured base URL

## Recommended Release Description

BreakPoint helps you preserve momentum before stepping away from your Mac. Trigger it from the menu bar or with `Cmd + Shift + Escape`, and it captures your current context into a structured Doom's Moment you can reopen later in Markdown or Apple Notes.

This release adds a cleaner settings experience with a configurable Pieces URL, an Ollama model picker, custom search tags for generated output, and faster generation fallback behavior.

## Notes For Users

- If Apple Notes export is enabled, macOS may ask for Automation and Accessibility permissions.
- If screenshot OCR is needed, macOS may ask for Screen Recording permission.
- Large cloud-backed Ollama models may still take noticeably longer than small local models.

## Known Limitations

- Apple Notes export depends on local macOS automation permissions.
- Current release builds still emit AppIcon asset warnings during Xcode build, but the notarized DMG is valid for distribution.
