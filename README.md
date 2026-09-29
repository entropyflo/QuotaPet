# QuotaPet

QuotaPet is an open-source, floating macOS desktop pet that shows the five-hour quota remaining for the current ChatGPT/Codex account and its reset countdown. The compact apple is drawn in SwiftUI; the full-size mode uses the bundled ten-stage apple sprite sheet.

> QuotaPet is an unofficial community project. It is not affiliated with, endorsed by, or sponsored by OpenAI. It does not depend on, modify, copy, or track any official ChatGPT pet.

[简体中文](README.zh-CN.md)

## Requirements

- macOS 14 or later
- Swift 6 / Xcode 16 or later
- A locally installed `codex` executable and a signed-in Codex account for live quota data

Apple Silicon is the primary tested architecture, but the source contains no architecture-specific dependency.

## Build and run

The app icon is generated from `Resources/AppIcon-1024.png`. The build script compiles the complete macOS icon set in `Resources/Assets.xcassets` into the application bundle with Apple's `actool`.

```sh
./scripts/test.sh
./scripts/build-app.sh
open build/QuotaPet.app
```

The app is ad-hoc signed for local use. It stays out of the Dock and provides all controls from the menu bar.

For downloadable builds, see GitHub Releases. The first public build is ad-hoc signed and not notarized, so macOS may require opening it from Finder's context menu and confirming it in Privacy & Security.

For UI development without an account:

```sh
.build/debug/QuotaPet --preview-state=95
.build/debug/QuotaPet --preview-state=20
.build/debug/QuotaPet --preview-state=0
.build/debug/QuotaPet --preview-state=offline
```

The same values work through `QUOTAPET_PREVIEW`. `--preview` defaults to 95%. Add `--preview-scale=0.5` or `--preview-scale=1` to inspect either fixed pet size without changing saved preferences.

## Data access

QuotaPet finds Codex from `CODEX_EXECUTABLE`, known ChatGPT/Homebrew locations, and `PATH`. It starts `codex app-server --listen stdio://`, performs the JSONL initialize handshake, reads `account/rateLimits/read`, and reacts to `account/rateLimits/updated`. It opens no network port.

QuotaPet does **not** read `~/.codex/auth.json`, call private ChatGPT HTTP endpoints, read conversations or project files, store credentials, store full App Server responses, or send telemetry. See [PRIVACY.md](PRIVACY.md).

## Behavior

- 300-minute windows are treated as five-hour quota; 10,080-minute windows as weekly quota.
- Remaining quota is clamped to 0–100%. Missing data is shown as unavailable, never as a fabricated 100%.
- Last successful data remains visible and is marked stale after connection failure.
- Refresh occurs on launch, every 60 seconds, on server notification, on Mac wake, and at the five-hour reset time.
- The non-activating transparent panel can be dragged and switched between persistent 0.5x and 1x sizes from its hover control or menu. It can also be locked, kept on top, shown on all Spaces/full-screen auxiliary spaces, or made click-through. Click-through can always be disabled from the menu bar.
- At 0.5x, quota becomes a circular ring around a static 2D apple. Percentage and reset time remain at full-size typography directly over the apple body, while its color shifts from fresh green to spoiled brown in ten-percent steps. At 1x, the bundled `apple-quota-10-stage-v2-cartoon.png` sprite sheet selects one stage for every ten percent consumed.
- In 1x mode, hovering morphs the five-hour and weekly quota glass surfaces with `GlassEffectContainer`, scoped `glassEffectID` values, and the native matched-geometry glass transition on macOS 26 or later. Older supported systems use the scale/material fallback.
- System light/dark appearance and Reduce Motion are respected.
- Quota cards and progress use native interactive Liquid Glass on macOS 26 or later, with a material-and-highlight fallback on macOS 14–15 and support for Reduce Transparency.

## Project layout

- `Sources/QuotaPet/App` — application lifecycle and menu bar
- `Sources/QuotaPet/Models` — app-facing presentation state (core data models live in the reusable core target)
- `Sources/QuotaPetCore` — models, quota provider, JSON-RPC, parsing and reconnect policy
- `Sources/QuotaPet/Services` — app integration boundary
- `Sources/QuotaPet/Views` — SwiftUI pet and quota UI
- `Sources/QuotaPet/Window` — non-activating AppKit panel
- `Tests` — deterministic unit tests

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/UNINSTALL.md](docs/UNINSTALL.md), and [docs/RELEASING.md](docs/RELEASING.md).

## Scope

Version 0.1 does not follow an official pet, support Windows/Linux or multiple accounts, draw token history charts, provide progression/shops/skins, ship through the App Store, consume reset credits, or auto-update.

## License

MIT. See [LICENSE](LICENSE).
