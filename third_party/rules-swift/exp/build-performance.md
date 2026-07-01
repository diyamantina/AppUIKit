# Build Performance Benefits

Why ExtremePackaging pays off in build time. Rationale, not rule. Read once for context.

### Incremental Compilation

**With ExtremePackaging:**
- Change AppFont → Only AppFont rebuilds
- Change AppComponents → Only AppComponents + dependent targets rebuild
- Change SharedModels → More rebuilds (foundation layer), but still isolated

**Without ExtremePackaging:**
- Change any file → Entire monolith rebuilds

### Parallel Builds

```
Build Graph (simplified):
SharedModels ─┬─> ApiClient ─┬─> AuthFeature ──> iosApp
              │               │
              └─> AppTheme ───┴─> AppFeature ───┘

SPM builds in parallel:
[SharedModels, AppFont] → [ApiClient, AppTheme, SharedViews] → [AuthFeature, AppFeature] → [iosApp]
```

SPM automatically parallelizes independent package builds.

### CI/CD Optimization

```yaml
# A CI runner can cache per-package
stages:
  - build-foundation
  - build-infrastructure
  - build-features
  - build-apps

build-foundation:
  script:
    - swift build --product SharedModels
    - swift build --product AppTheme
  # Cache: Only rebuild if foundation changed
```

## Acceptance check

This is a rationale doc, not a binding rule, so it ships an observable checklist a reviewer applies to
any change that touches the package graph, to confirm the build-time benefits above were preserved.
Each item is phrased so two reviewers agree:

- **Granularity preserved.** The change does not merge two single-responsibility packages into one, so
  a touch to one concern still rebuilds only that package and its dependents, not a wider blast radius.
  FAIL if files from two distinct responsibilities are folded into a single target.
- **No new wide-fan-in edge.** The change adds no dependency that makes a low-level, frequently-edited
  package gain many new dependents (which would force a large rebuild on every edit to it). FAIL if a
  foundation package gains a new upward dependency, or a widely-depended-on package starts depending on
  something volatile.
- **Parallelism intact.** Independent packages stay independent: the change introduces no edge that
  serialises two previously-parallel build branches without a real reason. PASS when the dependency
  graph remains a DAG whose independent branches SPM can still build concurrently.
- **Per-package CI caching still valid.** The change keeps the foundation, infrastructure, features,
  apps layering, so a CI runner can still cache and skip a layer that did not change. FAIL if a
  back-edge (a lower layer depending on a higher one) defeats per-layer caching.

A change that collapses granularity or adds a back-edge fails this checklist even if the build still
succeeds, because it forfeits the incremental, parallel, and cache-friendly build this document exists
to protect.

