# Apple UI Framework Policy (MANDATORY IN APPLE CLIENT TARGETS)

**Status: MANDATORY when selecting frameworks for an Apple client or UI target.**
Every UI-framework suggestion, comparison, recommendation, citation, and
dependency for that target stays inside Apple's own SDKs (SwiftUI, UIKit, AppKit,
Foundation, and the rest of Apple's frameworks) and the Swift-native ecosystem.
This is a hard boundary in code, comments, documentation, commit messages,
reviews, and conversation about the Apple presentation tier.

This policy does not govern framework-free domain or presentation models,
cross-platform libraries and CLIs, or Linux server targets. Those surfaces follow
[cross-platform.md](cross-platform.md) and, for production servers,
[linux-server.md](linux-server.md). Portability of
non-UI Swift code is compatible with this policy; a foreign UI toolkit in an
Apple client is not.

## The mandate

- **Apple frameworks only.** Suggest, compare against, recommend, or cite Apple's
  own SDKs and the Swift / Apple-native ecosystem, and nothing else. Swift-native
  community libraries are acceptable. Non-Apple product stacks are not.
- **Never name a non-Apple UI or cross-platform stack.** Do not introduce one as a
  dependency, do not suggest one, do not compare against one, do not validate a
  choice by pointing at one, and do not mention one as an aside or as "this is what
  others do." This holds for every Android, web, mobile, or cross-platform UI
  toolkit without exception. The prohibition is stated as a category on purpose:
  do not enumerate the banned stacks, do not name them at all. "I only cited it as
  neutral corroboration" is not a defence.
- **Keep platform-specific choices in their platform target.** Apple UI targets
  use Apple SDKs. Linux server and cross-platform targets use the Swift-native
  choices defined by their own rules and do not weaken the Apple presentation
  boundary.

## Concept versus rival framework: the exact line

Ecosystem-neutral academic and HCI theory may be referenced to explain a concept:
the architecture and interaction-design literature, the separation-of-concerns and
testability patterns, the layering models, and the like. The line is exact:

- **Allowed:** explaining a concept by way of vendor-neutral theory.
- **Forbidden:** naming a rival framework to adopt, to compare against, or to be
  validated by.

When an idea's most famous instance lives in a non-Apple stack, make the point
with an Apple-native or vendor-neutral example, or drop the example. Never reach
for the banned stack just because it is the canonical illustration.

## Why this exists

A non-Apple UI-framework reference in an Apple client, even an offhand one,
invites drift in dependencies, comparisons, and reviewer expectations. Holding
the presentation boundary keeps Apple UI decisions anchored to Apple's frameworks
without misclassifying a portable domain model or a Swift server as a violation.

## Acceptance check

An Apple-client or UI change conforms when: (1) no non-Apple UI or cross-platform
stack is named in that target's code, comments, docs, or commit text; (2) every
new presentation dependency is an Apple SDK or a Swift-native library; and (3)
any rival-framework comparison or "what others do" aside is absent. Cross-platform
domain code and Swift Linux/server code are audited under their companion rules,
not this acceptance check.

## Companion rules

- [cross-platform.md](cross-platform.md): portability boundaries for libraries, CLIs, and split
  Apple-client/Linux-server repositories.
- [linux-server.md](linux-server.md): operational choices for production Swift on Linux.
- [ui/native-per-platform.md](ui/native-per-platform.md): native presentation principles for each supported
  client platform.
