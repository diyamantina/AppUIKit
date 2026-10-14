# Critical Rules

Always-loaded core. Five rules that gate every internal SwiftPM target decision
under ExtremePackaging.

Follow the "ExtremePackaging" architecture pattern: one active Swift package with
maximum granular modularization into distinct targets. Each target represents a
single cohesive responsibility with explicit dependencies. This enables isolated
compilation, parallel builds, clear dependency graphs, and superior testability.

### Rule 1: Single Responsibility per Target

Create targets with one clear purpose:
- A single, well-defined responsibility per target
- Don't mix concerns (UI + networking, models + API client)
- Name communicates the purpose
- Independently buildable and testable

### Rule 2: Explicit Dependency Declaration

Declare dependencies explicitly in `Package.swift`:
- List all dependencies in the package manifest
- No implicit/transitive dependencies
- Minimise cross-target dependencies
- Prefer unidirectional dependency flow

### Rule 3: Target Granularity

Prefer smaller, focused targets over larger ones:
- Single-file targets are acceptable when the unit is genuinely standalone (typography, color foundation, a single protocol, a single transport).
- Separate by role, not by topical bundling: foundation primitives, infrastructure, protocols, middleware, services, per-feature or per-CLI-verb operation targets, front-door binaries.
- Each cohesive responsibility (a feature, a CLI verb, a middleware, a transport, a service) gets its own target.

### Rule 4: Naming Conventions

Follow a consistent naming scheme. Patterns that apply across project shapes:

- **Shared foundation:** `Shared*` for cross-target value-types, models, utilities, configuration (e.g. `SharedModels`, `SharedUtils`, `SharedConfiguration`).
- **Core infrastructure:** `Core*` or descriptive single-purpose names for the foundation domain (protocols, parsers, transports, indexers).
- **Per-feature or per-verb operation targets:** one target per user-facing flow (UI app) or one per CLI/MCP verb (CLI/MCP app). Name after the responsibility, not after a role suffix (`Distribution`, `Indexer`, `Ingest` in a CLI; the feature's own name in a UI app).
- **Service targets:** `*Service` or a `Services` aggregator for cross-layer read/write services consumed by multiple front-doors.
- **Aggregators:** umbrella targets only when the umbrella adds real value (preview hosts, all-features aggregators for app composition); don't add one by default.

Project-specific conventions (UI component packages, API client/server splits, design-system packages, hot-reload infrastructure) live in the project's own `AGENTS.md` or rule files, not in this always-loaded universal rule.

### Rule 5: Layer Architecture

Organize targets into clear architectural layers ordered bottom to top. Imports
and manifest dependencies point from higher-level consumers to lower-level
providers. The number and naming of layers varies per project shape; the constants
are:

- **Foundation** (bottom): shared value-types, models, primitive utilities, logging.
- **Infrastructure**: protocols, persistence, networking, file I/O, parsers, transports.
- **Domain**: services, indexers, business logic, per-feature or per-CLI-verb operation packages.
- **Presentation** (UI projects only): component packages, design-system packages, screens.
- **Front-door** (top): binary targets, apps, CLIs, MCP servers, preview hosts, test harnesses.

A lower layer never imports or declares a dependency on a higher layer. Build order
and dependent propagation travel upward, but the declared `depends on` relation
points downward. For the active project's actual layer instantiation, read the
active manifest: root `Package.swift` in a package repo,
`Packages/Package.swift` in a project monorepo.

## Acceptance check

The five rules are conforming when each is shown to hold for the active target graph:

- **The graph is acyclic and resolves.** SPM rejects a dependency cycle at resolution, so a clean resolve proves Rule 2's "no circular dependencies" floor:

```bash
swift package resolve && swift build
```

  Both MUST exit 0. A cycle makes resolution fail.

- **Dependencies are declared, not transitive.** Spot-check that every module a target's sources `import` appears in that target's `dependencies:` list (Rule 2). No target relies on a symbol reaching it only through another target's import.

- **Observable checklist** for the rules SPM does not enforce, each a clear pass/fail: every target has one cohesive responsibility, not a grab-bag of unrelated concerns (Rule 1); a target is split rather than grown when a second responsibility appears, and single-file targets are allowed when genuinely standalone (Rule 3); target names follow the scheme (`Shared*` foundation, `Core*` or descriptive infrastructure, per-feature/per-verb operation targets, `*Service` services, umbrella aggregators only when they add value) (Rule 4); and every import or manifest dependency goes from a higher-level consumer to a lower-level provider, never the reverse (Rule 5). A back-edge passes `swift build` but fails this checklist.
