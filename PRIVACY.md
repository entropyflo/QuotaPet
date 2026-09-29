# Privacy

QuotaPet is local-only software. It has no analytics, telemetry, advertising, crash-upload service, remote backend, or listening network port.

## Data read

QuotaPet starts the locally installed Codex executable as `codex app-server --listen stdio://`. Over that child process's standard input/output it performs the documented JSONL initialization handshake, calls the read-only `account/rateLimits/read` method, and listens for `account/rateLimits/updated` notifications.

Only quota window duration, used percentage, reset timestamp, fetch time, and connection health are retained in memory. Window position and user-selected display settings are stored in `UserDefaults`.

## Data never read or stored

QuotaPet does not read `~/.codex/auth.json`; directly call internal ChatGPT HTTP APIs; inspect conversations, prompts, responses, session content, or project files; or store account identifiers, tokens, cookies, credentials, or complete App Server responses. Sanitized diagnostics contain only executable availability, connection state, last successful refresh time, and stale status.

The Codex child process uses the user's existing local Codex authentication. QuotaPet neither accesses nor exports that authentication material.
