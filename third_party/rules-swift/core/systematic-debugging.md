# Systematic Debugging

Find and articulate the root cause of any bug, test failure, or unexpected behavior before proposing or applying a fix. Symptom fixes are forbidden until you can explain why the symptom occurs. This rule is language- and platform-agnostic.

This is the anti-shortcut procedure for bugs, the specialization of `no-shortcuts-first-principles.md` to the moment something is broken: silencing over solving is forbidden, and a fix you cannot explain is a cargo-cult edit.

## Core rules

### Rule 1: Reproduce first, investigate second, fix third

Complete the phases in order.

- Get a deterministic reproduction (a failing test, a sample input, a repro script) before reading code.
- Identify the smallest change that flips the outcome before naming it the cause.
- Do not propose a fix until you can describe the cause in one sentence.

### Rule 2: The four phases

```
1. REPRODUCE
   - capture the exact failing command or input
   - confirm it fails consistently
   - if flaky, treat the flake as the primary bug (the race is the cause)

2. ISOLATE
   - bisect: which component, which file, which line
   - for tests: shrink to the smallest failing assertion
   - for crashes: get the full stack trace with line numbers

3. EXPLAIN
   - state the root cause in one sentence
   - identify the invariant that was violated or the assumption that was wrong
   - if you cannot explain it, you have not found the cause yet

4. FIX
   - the smallest change that addresses the cause, not the symptom
   - add or update a test that would have caught it
   - re-run the suite and cite the result (see testing-discipline.md)
```

### Rule 3: Common pitfalls to check first

Consider these before deeper investigation. They are the recurring shapes a root cause tends to take, independent of language:

- **Null / absent value**: trace where a value that should exist became absent, rather than guarding the read site.
- **Concurrency**: was the failing code on the expected thread, task, or execution context? Look for shared mutable state, ordering assumptions, and missing synchronization.
- **Dependency wiring**: did the failing path receive the dependency it expected, or did a default / live implementation leak in where a test double was intended?
- **State and lifetime**: a value read before it was set, after it was freed, or from a stale copy.
- **Type / contract mismatch**: a fix that "looks right" but the compiler or runtime rejects is often hiding a wrong assumption about the contract.
- **Cache or stale build**: rebuild from clean if behavior contradicts the visible source.

### Rule 4: Banned behaviors during debugging

Do not:

- Apply a fix to make the test pass without understanding why it was failing.
- Wrap the failing call in an error-swallowing construct to silence the symptom.
- Add a synchronization or context annotation to "fix" a concurrency error without confirming the call site needed it.
- Disable, skip, or mark the failing test expected-to-fail and move on.
- Insert a sleep or retry to mask a timing bug whose race you have not explained.
- Attempt multiple fixes in parallel hoping one sticks.

If a fix does not hold, return to phase 2 (Isolate). Do not stack guesses.

### Rule 5: Reporting

State, in this order, when reporting on a debugging session:

1. The reproduction (command or input + expected vs actual).
2. The root cause (one sentence).
3. The fix (what changed and why it addresses the cause, not the symptom).
4. The verification (which test now passes that did not before, with counts).

### Rule 6: Debugging against a differential or parity oracle

When the bug is a disagreement with a reference (parity with a platform, two paths that must agree, a conformance corpus), the four phases still apply, but the FIX phase is iterative and the regression set is part of the instrument.

- **A regression from your fix is a measurement, not a defeat.** A fix that closes the target case but breaks another has just told you a case the rule must also satisfy. Read the new failure to refine the rule toward the exact behavior the authority exhibits, then re-run the whole parity corpus. Successive regressions converge the rule on the spec; do not abandon a correct direction at the first one.
- **Run the full parity set after every change.** The regression corpus is the specification you are reverse-engineering; a green target case with an unrun corpus proves nothing.
- **Revert a net-negative fix.** If the change trades a *benign* divergence, one that does not alter the observable output, for a *real* one that does, it is wrong even though it closes the original case. Revert it, pin the cases that were already correct, and disclose the gap with its evidence rather than shipping a regression. (See `oracle-first.md`: classify divergences; the comparison law decides what is observable.)
- **Classify the divergence by the comparator's visible unit before chasing it.** A difference that does not change the observable output, a caret index, an internal array order, a sub-threshold position, is not worth destabilizing a delicate, heavily-tested path to fix, and never worth trading for a real one.

## Anti-patterns

- "I think it might be X, let me try" applied to multiple guesses in series.
- Adding logging without a hypothesis to test.
- Reading the whole file looking for "something off" instead of bisecting.
- Calling a flake "transient" without finding the race.
- Declaring a fix complete because the failing test now passes, without checking why the others still pass.
- Abandoning a correct fix at its first regression instead of reading the regression as the case the rule has not yet satisfied.
- Trading a cosmetic parity diff for a real one to close the original ticket.

## Companion rules

- `no-shortcuts-first-principles.md`: the ethic this specializes. Silencing a symptom instead of fixing its cause is the canonical shortcut; if you reach for one, the cause is not understood yet.
- `testing-discipline.md`: the fix is not done until a test that would have caught the bug exists and the suite is re-run with cited counts.
- `proof-discipline.md`: how to frame and label what the fix proves versus what remains open.

## Acceptance check

A debugging change conforms when the issue, PR, commit message, or final report contains these observable items:

1. **Reproduction:** the exact failing command, input, or user action is named, with expected and actual behavior.
2. **Isolation:** the smallest implicated component, file, function, or invariant is named. If the failure was flaky, the race or nondeterministic condition is treated as the bug.
3. **Root cause:** one sentence explains why the symptom happened, including the wrong assumption or violated invariant.
4. **Fix:** the change addresses that cause directly. It does not swallow the error, skip the failing check, add a sleep, add a retry, broaden a catch, or apply unrelated guesses.
5. **Regression proof:** a test, fixture, assertion, or documented manual check that would have caught the bug is added or updated, unless the report states why no such check is possible.
6. **Verification:** the relevant suite is re-run and the command plus result counts are cited.

Runnable spot check:

```sh
rg -n 'try\\?|catch \\{|sleep\\(|Task\\.sleep|XCTSkip|\\.skip\\(|disabled|TODO.*test|swiftlint:disable' Sources/ Tests/
```

Every hit introduced by the debugging change must be justified in adjacent text as part of the root-cause fix. An unjustified hit fails this rule even if the immediate failing test now passes.
