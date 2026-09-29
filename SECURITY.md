# Security Policy

## Supported version

Security fixes currently target the latest source revision of QuotaPet 0.1.x on macOS 14 and later.

## Reporting a vulnerability

Please report vulnerabilities privately to the repository maintainers rather than opening a public issue containing exploit details or sensitive data. Include the affected revision, macOS version, reproduction steps, impact, and a minimal proof of concept. Do not include credentials, tokens, cookies, account identifiers, or complete App Server responses.

Maintainers should acknowledge a report within seven days, coordinate remediation and disclosure, and credit the reporter if requested.

## Security boundaries

QuotaPet launches only a discovered executable file named or configured as Codex and communicates over inherited stdio. Setting `CODEX_EXECUTABLE` trusts the specified local binary. QuotaPet opens no listener and does not parse authentication files. Release artifacts should be built, hardened-runtime signed, notarized, stapled, and verified as described in `docs/RELEASING.md`.
