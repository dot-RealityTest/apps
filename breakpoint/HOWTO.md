# BreakPoint - How To Guide

## Getting Started

### Prerequisites
- macOS
- Ollama installed and running
- Pieces OS running on the configured base URL

### Install Ollama
```bash
brew install ollama
ollama pull llama3.2
ollama serve
```

### Launch BreakPoint
1. Open `BreakPoint.app`
2. Look for the icon in the menu bar
3. No Dock icon appears because BreakPoint runs as a menu bar utility

### Pre-Notarization Permissions Check
Before notarization and release testing, verify these macOS permissions on a clean machine:
- Screen Recording for screenshot OCR and screen context capture
- Automation for Apple Notes export
- Accessibility if macOS prompts for control of Notes/System Events during Notes export

---

## Triggering Doom's Moment

### Option A: Left-click
Fastest way to trigger generation.

### Option B: Global hotkey
Press `Cmd + Shift + Escape` from anywhere.

### Option C: Right-click menu
Right-click the menu bar icon and choose `Doom's Moment`.

---

## What Happens During Generation

1. The menu bar icon switches into the animated thinking state
2. The popover shows `Generating...` in pink with the app icon
3. BreakPoint gathers screen and context data
4. BreakPoint attempts generation through Pieces QGPT first
5. If Pieces QGPT is unavailable or slow, it falls back to Ollama
6. Export runs according to the selected preset
7. Success or error state is shown in the popover

If a file export is included, the success message now includes the save location more explicitly.

---

## Export Presets

Set the export destination from `Properties`.

Available presets:
- `File`
- `Notes`
- `File + Notes`

### File
Writes a `.md` file only.

### Notes
Creates an Apple Note only.

### File + Notes
Writes the `.md` file and also creates the Apple Note.

### Current file location
In the current app setup, generated Markdown files are being saved to:
- `/Users/kika_hub/Documents/dooms`

Example filename:
- `DoomsMoment_2026-03-27_17-21-59.md`

---

## Choosing a Generation Mode

Open `Properties` from the right-click menu and choose one of these:

### Normal
Use for balanced, general-purpose context preservation.

### ADHD
Use when you want short, scannable re-entry notes.

### Code Mode
Use during development sessions when you want code-aware output.

### Extra
Use when you want the most detailed handoff without code-heavy formatting.

`Extra` is designed to produce stronger Markdown structure, including:
- executive summary
- active projects
- grouped priorities
- decisions, risks, and open loops
- resume plan
- learn and explore
- hashtags

---

## Using the Right-Click Menu

The right-click menu includes:
- mode label
- export label
- Pieces status
- `Doom's Moment`
- `Open Latest Doom's Moment`
- `Reveal Export Folder`
- `Open Doom Moments in Notes`
- `Copy Last Output Path`
- `Properties`
- `Close App`

Notes:
- latest-file actions are disabled if the current export preset does not include file output
- the context menu is isolated from the status popover to avoid old popup races

---

## Configuring Settings

Open `Properties` from the right-click menu.

### Change Export Preset
1. Open `Properties`
2. Find the `Export` picker
3. Choose `File`, `Notes`, or `File + Notes`

### Change Export Folder
1. Open `Properties`
2. Edit `Export Folder` or click `Browse`
3. Choose the target directory

### Configure Ollama
1. Set the base URL
2. Use the model dropdown to pick from available models
3. Click `Refresh Models` if you changed the Ollama instance or just pulled a new model
4. Click `Test Connectivity`

### Configure Pieces OS
1. Start Pieces OS
2. Set the Pieces base URL if it is not `http://localhost:39300`
3. Enable `Use Pieces for Doom's Moment generation`
4. Test the connection from `Properties`

### Add Search Tags
1. Open `Properties`
2. Find `Search Tags`
3. Enter comma-separated tags like `work, client-a, follow-up`
4. Generate a new Doom's Moment

These tags are sanitized into hashtags and added to the generated `## Hashtags` section in both Markdown files and Apple Notes exports.

---

## Reading the Result

### Markdown file
Open the saved `.md` file from the export folder.

### Apple Notes
Use `Open Doom Moments in Notes` from the right-click menu, or open Notes manually.

### Re-entry flow
1. open the latest generated file or note
2. scan the priorities and active projects
3. use the resume plan to get back into the work quickly

---

## Troubleshooting

### It says it failed, but I expected a file
Check the selected export preset first.
- `Notes` does not create a file
- `File` and `File + Notes` do

### I can't find the file
Use:
- `Reveal Export Folder`
- `Open Latest Doom's Moment`
- `Copy Last Output Path`

### Notes export failed
- check Automation permissions for Notes
- ensure Notes can be controlled by BreakPoint

### Menu bar icon not visible
- check menu bar overflow
- use `Cmd + Shift + Escape` as fallback

### Pieces OS not connecting
- ensure Pieces OS is running
- verify the configured Pieces base URL
- test from `Properties`

### OCR not capturing text
- check Screen Recording permission in macOS Privacy settings

### Generation takes too long
- try a faster Ollama model from the dropdown if you are using a large cloud model
- use `File` export temporarily if you want to rule out Apple Notes automation delays
- confirm Pieces and Ollama both pass their test buttons in `Properties`

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + Shift + Escape` | Trigger Doom's Moment |
| Left-click menu bar icon | Trigger Doom's Moment |
| Right-click menu bar icon | Open context menu |
