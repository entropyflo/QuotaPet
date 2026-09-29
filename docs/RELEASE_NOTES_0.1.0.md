# QuotaPet 0.1.0

QuotaPet 0.1.0 is the first public release of the unofficial macOS floating quota pet for ChatGPT/Codex.

## Highlights

- Displays the current account's five-hour quota and reset countdown.
- Reveals weekly quota details on hover.
- Includes persistent 0.5x and 1x apple modes.
- Supports dragging, position locking, click-through, always-on-top, all Spaces, full-screen auxiliary spaces, and launch at login.
- Uses native interactive Liquid Glass on macOS 26 and later, with a compatible material fallback on macOS 14–15.
- Reads quota only through the local `codex app-server` JSON-RPC interface.

## Requirements

- macOS 14 or later.
- A local Codex installation and signed-in account for live quota data.

## Installation

1. Download `QuotaPet-0.1.0-macOS.zip` and expand it.
2. Move `QuotaPet.app` to `/Applications` if desired.
3. Open the app and use the menu-bar icon for settings and quitting.

This first downloadable build is ad-hoc signed and not notarized. macOS may require using **Open** from Finder's context menu and confirming the launch in **System Settings → Privacy & Security**. See `docs/RELEASING.md` for the Developer ID and notarization process intended for future signed releases.

## Integrity

The release includes `QuotaPet-0.1.0-macOS.zip.sha256` for verification.

QuotaPet is an unofficial community project and is not affiliated with, endorsed by, or sponsored by OpenAI.
