---
name: create-feature
description: "Scaffold a new MVVM-C feature for the ZanzarProject SwiftUI/Xcode app, with Views, ViewModels, Models, and an API/Service layer wired to the shared NetworkClient and AppCoordinator navigation. Use when the user asks to create, add, build, scaffold, implement, generate, or set up a new feature, screen, view, page, flow, form, or module in ZanzarProject — e.g. 'add a new feature for X', 'create a screen that lets users do X', 'implement a feature to submit/view/edit X', 'scaffold the X feature', 'build a new view for X', 'add a settings/profile/report/list/detail screen', 'wire up a new feature end to end'. Also use when asked to add a new API call, service, or network request following the project's existing layering, or to wire a new screen into app navigation/AppCoordinator."
---

# Create Feature

IRON LAW: A ViewModel may only depend on its feature's `<Feature>Servicing` protocol — never `NetworkClient`, `URLSession`, or any concrete network type directly. Every feature folder is produced by `scripts/scaffold_feature.py` — never hand-created file by file.

## Workflow

Copy this checklist and check off items as you complete them:

```
Create Feature Progress:

- [ ] Step 1: Understand the feature ⚠️ REQUIRED
  - [ ] 1.1 PascalCase feature name (e.g. IssueReport)
  - [ ] 1.2 What data does it send/receive? What screens/actions?
  - [ ] 1.3 Reached by push, sheet, or full-screen cover?
  - [ ] 1.4 Anything ambiguous about fields/endpoints/behavior? Ask, don't invent.
- [ ] Step 2: Scaffold ⛔ BLOCKING
  - [ ] Run scripts/scaffold_feature.py <FeatureName>
  - [ ] Review its report (created vs. already-existing files)
- [ ] Step 3: Implement API layer (Request/Response + endpoint path)
- [ ] Step 4: Implement domain Model
- [ ] Step 5: Implement ViewModel ⚠️ REQUIRED — invoke swift-concurrency skill
  - [ ] State + actions, Servicing protocol only
- [ ] Step 6: Implement View ⚠️ REQUIRED — invoke swiftui-pro skill
  - [ ] UI + Components for extracted subviews
- [ ] Step 7: Wire navigation ⚠️ REQUIRED — confirm before editing shared files
  - [ ] Load references/coordinator-wiring.md
  - [ ] Add Route/Sheet/FullScreenCover case + AppCoordinator view(for:) case
  - [ ] Add the calling-site trigger (button/action that navigates here)
  - [ ] (conditional) First feature ever: wiring NavigationStack into ContentView — confirm with user first
- [ ] Step 8: Fill in the test stub ⚠️ REQUIRED — invoke swift-testing-expert skill
- [ ] Step 9: Pre-delivery checklist ⚠️ REQUIRED
```

## Step 1: Understand the feature

Ask yourself: could I name every field the Service's Request/Response need, and
every user-visible action the ViewModel exposes, right now? If not, that's what
to ask the user before scaffolding — not something to invent so the feature
"looks done."

If the feature is reached from an existing screen, ask: is this a full
navigation push, a transient sheet, or a focused full-screen flow? See
references/coordinator-wiring.md § 1 if it's not obvious from the request.

## Step 2: Scaffold ⛔ BLOCKING

```bash
python3 scripts/scaffold_feature.py <FeatureName>
```

`<FeatureName>` must be PascalCase. The script:
- Auto-detects the repo root by locating `ZanzarProject/ZanzarProject.xcodeproj` (override with `--repo-root` if run from elsewhere)
- On the very first run in this repo, bootstraps `App/`, `Coordinator/` (`AppCoordinator.swift`, `Routes.swift`), and `Utils/NetworkClient.swift`, and moves the existing `ContentView.swift`/`MyApp.swift` into `App/`
- Creates `Features/<FeatureName>/{API,Models,ViewModels,Views,Views/Components}` with boilerplate files
- Creates `ZanzarProjectTests/<FeatureName>/<FeatureName>ViewModelTests.swift`
- Never overwrites a file that already exists — reruns are safe, existing work is never clobbered

The Xcode project uses file-system-synchronized groups, so every file the
script creates is picked up by the build target automatically — no
`.xcodeproj` editing is needed or should be attempted.

If the bootstrap step will run (check the script's report, or check whether
`Coordinator/AppCoordinator.swift` exists yet) — it moves the app's entry
files and creates shared infrastructure other features will depend on. Tell
the user this is happening before or as you run it.

Load references/architecture.md for the full layer contract and folder
structure before writing any implementation code.

## Steps 3–6: Implement the layers

Fill in the TODOs the script left behind, in order: API (Request/Response +
real endpoint path) → Models (domain type + how it maps from Response) →
ViewModel → View.

For the ViewModel (Step 5) and View (Step 6), invoke the project's own
skills instead of writing Swift/SwiftUI from general knowledge:
- **swift-concurrency** — for the ViewModel's async actions, task/actor
  usage, and any `@MainActor`/Sendable correctness (this project defaults to
  `MainActor` isolation and uses Swift's modern concurrency throughout).
- **swiftui-pro** — for the View's layout, modern SwiftUI APIs, and
  maintainability/performance review of what you write.

Ask, for the ViewModel specifically: does every method that hits the network
set `isLoading` and handle the thrown error? A feature with no loading/error
state on a network action is usually incomplete, not simple.

## Step 7: Wire navigation ⚠️ REQUIRED

Load references/coordinator-wiring.md. `Routes.swift` and `AppCoordinator.swift`
are shared files — read them before editing, and confirm with the user before
changing `App/ContentView.swift` (only needed the first time a feature is
wired in). A feature with no Route/Sheet case and no calling-site trigger is
unreachable and not done, even if the layer files are complete.

## Step 8: Test stub

Invoke the **swift-testing-expert** skill to replace the placeholder `@Test`
and `Mock<Feature>Service` in `<Feature>ViewModelTests.swift` with real,
well-structured Swift Testing assertions exercising at least one ViewModel
action against the mock — don't hand-write the test from general knowledge.

## Anti-Patterns

- Do NOT let the ViewModel call `NetworkClient`/`URLSession` directly — only through the feature's `Servicing` protocol.
- Do NOT hand-create feature files/folders — always `scripts/scaffold_feature.py`, even for a "quick" feature.
- Do NOT collapse the domain Model and the API Request/Response into one type — keep the mapping seam.
- Do NOT invent endpoint paths, field names, or business rules the user didn't specify — ask, or leave the script's TODO in place and flag it.
- Do NOT use `ObservableObject`/`@Published` — this project uses `@Observable`.
- Do NOT skip wiring the feature into `AppCoordinator` — an unreachable screen isn't a finished feature.
- Do NOT leave the test stub as a no-op — write a real `@Test` before calling the feature done.

## Pre-Delivery Checklist

### Correctness
- [ ] `scripts/scaffold_feature.py` was run and its report reviewed (no hand-created files)
- [ ] ViewModel has no networking imports — only the feature's `Servicing` protocol
- [ ] Service protocol methods match exactly what the ViewModel calls
- [ ] Feature is reachable: Route/Sheet/FullScreenCover case added, `AppCoordinator.view(for:)` updated, a real calling site triggers it

### Architecture
- [ ] Every file is in its correct layer folder (API / Models / ViewModels / Views / Views/Components)
- [ ] Domain Model (`Models/`) is distinct from the wire-format Request/Response (`API/`)
- [ ] `<FeatureName>` is PascalCase and identical across every generated type and file

### Completeness
- [ ] At least one real, non-placeholder `@Test` exercises the ViewModel via the mock service
- [ ] No unresolved `// TODO` left in fields/logic the user actually specified
- [ ] All workflow checklist items above are checked off
