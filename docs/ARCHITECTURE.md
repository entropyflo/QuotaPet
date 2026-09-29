# Architecture

## Components

`QuotaPetCore` is UI-independent. `QuotaProvider` isolates data access from presentation. `CodexAppServerProvider` owns the child process, JSONL framing, request IDs, response matching, update notifications, process cleanup, and capped exponential reconnect. `MockQuotaProvider` produces deterministic preview and test data.

`RateLimitParser` recursively extracts only quota-window fields from a response. Selection is based on `windowDurationMins`, never the primary/secondary position. It returns a five-hour window only for 300 minutes and a weekly window only for 10,080 minutes. Full JSON payloads are not persisted or surfaced to the UI.

`AppState` is the main-actor presentation coordinator. It consumes provider events, keeps the last successful snapshot, marks it stale on disconnect, and schedules launch, 60-second, notification-triggered, wake, and exact reset refreshes.

`PetPanelController` owns a transparent borderless `.nonactivatingPanel`. The panel joins all Spaces, participates as a full-screen auxiliary, restores only frames intersecting a current display, and switches mouse handling, movement, and window level from menu settings. The SwiftUI view knows only `AppState`/quota models and never JSON-RPC.

## Data flow

```text
codex child process (stdio JSONL)
        ↓
CodexAppServerProvider ── implements QuotaProvider ── MockQuotaProvider
        ↓ parsed QuotaSnapshot / connection events
AppState
        ├── MenuBarContent
        └── PetPanelController → PetView
```

## Lifecycle and failure behavior

The provider initializes before requesting rate limits. A server exit marks data stale and reconnects at 1, 2, 4, … seconds capped at 60 seconds. Explicit quit disables reconnect, closes stdin, and terminates the child. Missing five-hour quota remains `nil` and is rendered as unavailable.
