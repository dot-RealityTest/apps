# IconCraft

React/Vite app for generating macOS and mobile icon assets from a single source image. The project now also includes a Tauri desktop shell for building a native macOS app.

## Local development

```bash
npm install
npm run dev
```

The Vite dev server will print a local URL, usually `http://localhost:5173`.

## Production build

```bash
npm run build
npm run preview
```

## macOS desktop app

Run the desktop app in development:

```bash
npm run tauri:dev
```

Build a native macOS bundle:

```bash
npm run tauri:build
```

On macOS, the packaged `.app` and installer artifacts are generated under `src-tauri/target/release/bundle/`.

Primary outputs:

- `src-tauri/target/release/bundle/macos/IconCraft.app`
- `src-tauri/target/release/bundle/dmg/IconCraft_0.1.0_aarch64.dmg`

For a short handoff guide, see [HOWTO.md](/Users/kika_hub/Documents/Codex/iconcraft/HOWTO.md).
For a feature overview, see [FEATURES.md](/Users/kika_hub/Documents/Codex/iconcraft/FEATURES.md).

## Features

- Upload PNG, JPG, or SVG artwork
- Preview required macOS icon sizes
- Crop and adjust padding before export
- Export as:
  - `.iconset` ZIP
  - `.icns`
  - Xcode asset catalog ZIP
  - React Native iOS icon ZIP

## Deployment

This is a standard static Vite SPA and can be deployed to Vercel, Netlify, Cloudflare Pages, or any static hosting platform.
