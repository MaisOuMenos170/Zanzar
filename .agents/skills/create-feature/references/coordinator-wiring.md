# Wiring a feature into AppCoordinator

This is a manual edit, not a script step: `Routes.swift` and `AppCoordinator.swift`
are shared files every feature touches, so blind text-insertion is too fragile
(enum bodies, existing cases, switch exhaustiveness). Read each file first, then
edit it the same way you'd extend any existing Swift enum/switch.

## 1. Decide push vs. sheet vs. full-screen cover

Ask: does this feature replace the current screen in a navigation flow (push),
float above it temporarily (sheet), or take over the whole screen for a focused
task like onboarding or a modal form (full-screen cover)?

A single-screen form like `IssueReport` triggered from a "Report an issue"
button is usually a **push** (`Route`) if reached from a menu/settings-style
flow, or a **sheet** if reached from an in-context "..." action. If it isn't
obvious from the request, ask the user rather than guessing.

## 2. Add the case to Routes.swift

Open `Coordinator/Routes.swift` and add one case to the relevant enum:

```swift
enum Route: Hashable {
    case issueReport   // <- added
}
```

If the destination needs data (e.g. an id), carry it as an associated value:

```swift
case issueReport(contextID: UUID)
```

`Sheet` and `FullScreenCover` compute `id` with `switch self {}` — valid only
while the enum has zero cases. Adding the first case there will fail to
compile until you also handle it in that switch (returning `self` for the new
case is enough); do this in the same edit, not as an afterthought.

## 3. Add the case to AppCoordinator's view builder

Open `Coordinator/AppCoordinator.swift` and add the matching case to the
corresponding `@ViewBuilder func view(for:)`, **above** its `default:`:

```swift
@ViewBuilder
func view(for route: Route) -> some View {
    switch route {
    case .issueReport:
        IssueReportView()
    default:
        EmptyView()
    }
}
```

The `default: EmptyView()` means the compiler will NOT catch a route you
forget to wire here — it silently renders blank instead of failing to build.
After adding the case, double-check by eye (or search the file for the route
name) that it's actually handled, since nothing else will catch the mistake.

## 4. Trigger the navigation from the calling site

Wherever the user taps the entry point (a button in an existing View, likely
outside this feature's own folder), call the coordinator:

```swift
@Environment(AppCoordinator.self) private var coordinator
// ...
Button("Report an issue") { coordinator.push(.issueReport) }
```

For a sheet: `coordinator.present(sheet: .issueReport)`.

## 5. First feature only: wire the root App/ContentView

If `App/ContentView.swift` doesn't yet own an `AppCoordinator` and
`NavigationStack`, this is the first feature being wired in. Confirm with the
user before editing these shared entry-point files, then:

```swift
struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // existing root content
        }
        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
        .sheet(item: $coordinator.presentedSheet) { coordinator.view(for: $0) }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { coordinator.view(for: $0) }
        .environment(coordinator)
    }
}
```

Adjust to whatever root content `ContentView` already renders — this only adds
the coordinator plumbing around it.
