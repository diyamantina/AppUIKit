# Security Policy

## Supported Versions

This package is pre-1.0 and under active development. Security fixes are applied
to the `main` branch; there are no separately maintained release branches yet.

| Version | Supported |
|---------|-----------|
| `main`  | yes       |

## Reporting a Vulnerability

Please report security vulnerabilities **privately**. Do not open a public
GitHub issue for a security problem.

- Preferred: use GitHub's **Report a vulnerability** (Security advisories) on this
  repository.
- Alternatively, email **mihaelamj@me.com** with the details.

Please include:

- A description of the vulnerability and its impact.
- Steps to reproduce.
- Your platform / Swift version.

You can expect an acknowledgement within a few days. We will keep you informed as
the issue is investigated and fixed, and will credit you in the release notes
unless you prefer to remain anonymous.

## Scope

AppUIKit is a thin namespace layer (type aliases and small UI helpers) over AppKit
and UIKit. Its attack surface is limited, but issues such as unsafe handling of
pasteboard contents or untrusted strings passed to its helpers are in scope.
