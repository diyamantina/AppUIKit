# Oracle First (MANDATORY)

**Status: MANDATORY when designing, building, rebuilding, or substantially extending any system or correctness surface.** Before production architecture, before performance work, and before "does it work" tests, build the Oracle: the independent answer key that says what correct output is, how it is compared, and which cases are outside the current claim. For a tiny system, the Oracle may be tiny: one invariant, one closed-form example, one round-trip law, or one executable contract. It still comes first.

An Oracle is not just a test suite and not necessarily an external implementation. It is the correctness instrument for the system: the thing that can answer, for a given input, **what should have happened?** It may be a closed-form equation, a slow reference implementation, a live platform witness, a differential path, a curated corpus with a tolerance ledger, or a single canonical definition that prevents two paths from drifting. The implementation is not done until it passes the Oracle gate or the remaining frontier is named.

## The core rule

The first design artifact for a system MUST be its Oracle plan. The first runnable slice SHOULD be the smallest Oracle-backed slice. A production implementation without an Oracle is not "untested"; it is ungrounded.

Before writing the production path, state:

- **Correctness question.** What observable output must be right: bytes, pixels, layout frames, glyph ids, diagnostics, database rows, state transitions, network messages, numeric values, or something else.
- **Input domain.** Which inputs are in scope now, which are malformed, which are intentionally unsupported, and which are blocked.
- **Authority.** What makes the expected answer correct: specification clause, closed form, public formula, simpler reference implementation, live platform behavior, independent backend, curated fixture, or canonical shared definition.
- **Equivalence relation.** What counts as equal: byte-identical, structurally equal, same sorted set, same pixels, same floats within a derived bound, same diagnostics at the same source location.
- **Failure report.** What evidence a failing case must produce: fixture name, seed, input, expected, actual, comparator, tolerance id if any, and the unsupported/divergence status if it did not compare.

If those five things are not known, the system is not ready for production implementation.

## Choose the strongest Oracle available

Prefer the Oracle with the strongest claim. Do not use a weaker witness when a stronger one is available.

1. **Analytic / closed-form Oracle.** Best when the domain has math: geometry, transforms, physics, interpolation, codecs, color operations, parsers with formal grammars. The expected answer is derived from the formula or spec, not from another implementation.
2. **Slow literate reference implementation.** Best when the production system will be optimized, parallel, cached, GPU-backed, distributed, or otherwise hard to inspect. The reference is simple, direct, correctness-first, and allowed to be slow.
3. **Differential Oracle.** Best when the same source can travel through two independent paths: two lowerers, two backends, encode/decode, compiler/interpreter, software/GPU, direct engine/compiled engine. A disagreement localizes a defect.
4. **Live platform or external reference witness.** Use when the project explicitly claims behavioral parity with a platform, library, vendor renderer, browser, database, or OS API. Isolate it in an oracle/test target. Treat it as a fallible witness unless behavioral parity with that implementation is itself the spec.
5. **Evidence-ledger Oracle.** Use when correctness depends on a corpus, tolerance policy, or external toolchain. Pin the tool version, curate the corpus, keep a machine-readable tolerance ledger, keep a divergence ledger, and require every threshold to carry evidence.
6. **Single canonical definition.** Use when drift can be designed out. Generate both sides or route both paths through one definition, then test the independent invariants around it. This is stronger than hand-writing twin definitions and hoping they agree.
7. **Runtime fallback Oracle.** Use when fast paths are optional. A slow software path or reference backend remains always available; optimized paths must prove parity or fall back.

Stored golden files are a backstop, not the primary Oracle, unless the artifact is itself the product. A golden image or snapshot rots when the engine changes; a live differential or closed-form Oracle explains why the new output is right or wrong.

## Build the Oracle before the system

The Oracle must exist early enough to shape the implementation.

- The first feature slice MUST include the Oracle harness or a documented Oracle plan with the exact missing blocker. Do not build the production engine first and promise to "add conformance later."
- The Oracle SHOULD be smaller and simpler than the system it checks. If the checker is as complex as the implementation, it needs its own Oracle or a narrower claim.
- Production code MUST NOT import a test-only Oracle. Keep the dependency one-way: tests and conformance tools may depend on production; production must not depend on the test oracle.
- If the Oracle is also a runtime fallback, name that explicitly and keep the contract sharp: the fallback is the correctness path; optimized paths are optional accelerators.
- Every new feature MUST co-land with its Oracle case, fixture, or stated unsupported report. Backfilled correctness is a debt, not a plan.

## Define comparison before implementation

The comparator is part of the Oracle. It must be designed before a failure forces negotiation.

- Use exact equality by default.
- Use tolerance only when exact equality is impossible for a named reason: antialiasing, floating-point order, platform font hinting, nondeterministic scheduling, lossy compression, clock resolution.
- Every tolerance MUST be derived or measured. A round number with no derivation is an invented number.
- Every tolerance SHOULD have an id and a ledger entry naming: feature, unit, comparator, threshold, reason, derivation status, arithmetic model, evidence, and at least one counterexample just outside the bound.
- Do not scatter numeric thresholds through tests. Put them behind named comparators or a ledger so the policy is reviewable.
- A comparison report MUST show enough data to reproduce and explain the mismatch: input id, seed if any, expected, actual, delta, tolerance id, and status.

If a test says `<= 0.05` and no artifact explains why `0.05` is correct, the Oracle is incomplete.

## Preserve independence

An Oracle catches bugs only to the extent that it does not share the same bug.

- Do not copy production logic into the Oracle. Re-derive from the spec, use closed form, use a simpler algorithm, or run an independent path.
- If both sides intentionally share a canonical primitive, say so. Then the Oracle no longer proves that primitive; it proves that all consumers use the same primitive and that the primitive satisfies independent invariants.
- External implementations are witnesses, not automatically truth. Specs and closed forms outrank vendor behavior unless the product's explicit promise is vendor parity.
- When the Oracle and implementation might share a derivation error, audit the Oracle with a second witness: a live platform, a closed-form case, a fault injection, or a hand-computed counterexample.
- Add negative controls. The Oracle must fail when the implementation is deliberately wrong in a representative way.

A passing implementation and a passing Oracle can still both be wrong if they share the same mistaken assumption. The rule requires an audit path for that possibility.

## A codified expectation is a witness, not a verdict

Once a system has tests, property invariants, "laws", golden values, and issue write-ups, those become **codified expectations**, and a codified expectation can encode the wrong behavior exactly as a reference implementation can be a fallible witness. When a pinned test, a property law, a golden value, or an issue's stated root cause disagrees with the live Oracle or the authority (a specification clause, the source data, the strongest available witness), the expectation is a **suspect**, not the answer. Re-derive the correct result from the authority before assuming the production code is the wrong side.

- When the Oracle and a codified expectation disagree, derive the answer from the **authority**: the spec clause, the source data, the strongest available Oracle. Then fix whichever of {code, test, law, issue} is wrong. Often it is the expectation, not the code.
- A property or invariant that asserts **more than the spec guarantees** is itself a defect. Restate it to its true, provable form with the clause cited; do not strengthen the code to satisfy a false law, and do not weaken a law to silence a real failure. Tell the two apart by deriving the spec's actual guarantee, not by which change makes the bar go green.
- Treat an issue's or a prior note's stated root cause as a **hypothesis to verify against the authority**, not a fact to implement against. A confident, wrong diagnosis sends the fix to the wrong layer.
- A golden value or fixture inherits no authority from being checked in. When it conflicts with a fresh re-derivation from the spec, the golden is the suspect.

WRONG:

```text
A property test fails after a fix. Weaken the assertion until it passes.
An issue says "the bundled table is stale, regenerate it." Regenerate it without checking the source.
```

RIGHT:

```text
Re-derive the invariant from the spec. If the test encoded behavior stricter than the spec guarantees, restate the test to the spec's true invariant (clause cited) and keep the fix; if the code violated a real invariant, fix the code. If the issue's stated cause contradicts the source data, correct the issue and fix the layer that actually owns the defect.
```

## Classify every case

Every input must land in exactly one bucket:

- **handled**: compared against the Oracle and passed;
- **failed**: compared against the Oracle and did not pass;
- **unsupported**: reported as unsupported before producing a misleading result;
- **intentionally divergent**: different by design, with the reason named;
- **ineligible**: not compared because a prerequisite was absent, with the missing prerequisite named;
- **blocked**: not currently decidable, with the blocker and next instrument named.

Silent skip is forbidden. A missing font, absent GPU, unavailable reference tool, unsupported syntax node, or invalid fixture must not make the suite pass vacuously. The harness must emit a non-vacuity check: at least one real eligible case exercised each claimed surface, or the run reports that the surface was not proven.

## Use generated and randomized trips carefully

Generated cases and randomized differential trips are powerful only when reproducible.

- Seed every randomized run and print the seed on failure.
- Minimize or save failing inputs when possible.
- Generate by coverage design, not blind Cartesian explosion: boundaries, degenerates, pairwise interactions, order-sensitive permutations, and malformed cases.
- Keep curated fixtures separate from discovery corpora. Discovery finds bugs; curated fixtures prevent regressions.
- Do not let random passing replace named boundary cases. Random tests supplement the Oracle; they do not define it.

## Optimized paths must prove parity or fall back

For systems with multiple backends, caches, accelerators, or approximations:

- A slow exact path SHOULD exist first.
- A fast path MUST declare what it supports.
- The caller MUST route unsupported cases to the Oracle/fallback path or report unsupported; it must not approximate silently.
- Parity tests MUST assert that the fast path actually claimed support before comparing output. A skipped fast path is not a parity pass.
- Whole-output averages are insufficient when they can hide local errors. Compare at the unit where a defect would be visible: per byte, per pixel region, per glyph, per row, per event, per source span.

Speed is allowed only after correctness is established. The optimized path inherits the right to exist from parity with the Oracle.

## WRONG / RIGHT

WRONG:

```text
Build the renderer, inspect a few screenshots, save one PNG as a golden, and call it done.
```

RIGHT:

```text
Build a slow software/reference renderer first, define pixel equality and antialiasing tolerance, add analytic shape cases, add negative controls, then require the renderer to match the reference or report the unsupported feature.
```

WRONG:

```text
Use a platform framework as "the oracle" for every case, even when the public spec gives a closed-form answer.
```

RIGHT:

```text
Use the spec or closed form as ground truth. Use the platform framework as a witness. If the product promise is exact platform parity, isolate the platform harness and state that behavioral parity is the spec for that surface.
```

WRONG:

```text
Skip the conformance test when the reference tool, GPU, font, fixture, or network service is missing.
```

RIGHT:

```text
Report the case as ineligible with the missing prerequisite, and require a non-vacuity assertion for every surface claimed proven by the run.
```

WRONG:

```text
Let the GPU backend render unsupported blend modes "close enough."
```

RIGHT:

```text
Have the GPU backend declare unsupported blend modes, route them to the software Oracle, and add a parity test for every blend mode it does claim.
```

## Acceptance check

A new or substantially changed system conforms when:

1. An Oracle plan exists before the production implementation claim, naming the correctness question, input domain, authority, equivalence relation, and failure report.
2. A runnable Oracle harness, reference implementation, closed-form check, differential path, generated canonical definition, or explicitly blocked Oracle plan exists in the repo.
3. The Oracle is independent from production logic, or the shared canonical definition is named and independent invariants cover the shared primitive.
4. The comparator uses exact equality or a named, derived/measured tolerance. Grep finds no unexplained magic tolerance added by the change.
5. The harness has at least one negative control, counterexample, fault injection, or deliberately wrong case proving the Oracle can fail.
6. Unsupported, intentionally divergent, ineligible, and blocked cases are reported explicitly. No case disappears through a silent skip.
7. Random or generated cases are reproducible by seed or fixture id.
8. Optimized paths either pass parity against the Oracle or fall back/report unsupported.
9. The completion report states which Oracle gate ran and what it proved. If the gate did not run, the report names the blocker and the unproven frontier.
10. When the change resolved a conflict between the implementation and a codified expectation (a test, a property law, a golden value, an issue's stated cause), the resolution cites the authority (spec clause, source data, or stronger Oracle) that decided which side was wrong. It did not weaken a real invariant to pass, nor strengthen the code to satisfy a false one.

A system that ships production behavior first and adds an answer key later fails this rule even if conventional tests pass. A system with a beautiful test suite but no independent way to know the expected answer also fails this rule.

## Companion rules

- `no-shortcuts-first-principles.md`: the ethic this specializes. Building without an answer key is partial coverage dressed as correctness.
- `proof-discipline.md`: how to label what the Oracle proves, witnesses, samples, assumes, or leaves blocked.
- `testing-discipline.md`: how the Oracle becomes executable tests and gates.
- `verification.md`: no completion claim without fresh Oracle/test evidence.
- `round-trip-transformation.md`: the special case where the Oracle is the round-trip law and the invertible construction.
- `first-principles-analysis.md`: how to derive and record measured bounds, counts, and tolerance evidence.
- `systematic-debugging.md`: when the Oracle fails, reproduce, isolate, explain, then fix.

## Why this exists

Most systems are built backward: implementation first, tests second, correctness story last. That creates polished machinery with no independent answer to "is this right?" The Oracle-first rule reverses the order. It forces the team to define truth before optimizing toward it, exposes unsupported cases before they become silent wrong output, and makes correctness a designed artifact rather than an after-the-fact argument.
