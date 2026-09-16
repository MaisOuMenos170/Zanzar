# Critérios — Boilerplate iOS SwiftUI (ZanzarProject)

Load this file during Step 3 for the selected `--area`.

## structure

Ask for each item:

| Check | Question |
|-------|----------|
| Entry point | Is `@main` in a file named for the app (not `MyApp`)? Does it compose root navigation? |
| Feature folders | Is there a place for features (`Features/`, `Screens/`) or everything lives at root? |
| Core vs UI | Are models, services, and views separated or mixed in one file? |
| Naming | Do types reflect Zanzar domain or Xcode defaults (`ContentView`, `Item`)? |
| Scale path | Can a second screen land without restructuring? |

Red flags:
- Single `ContentView.swift` as entire app
- No `NavigationStack` when multi-screen product is planned
- Playground imports left in production targets

## tests

Ask:

| Check | Question |
|-------|----------|
| Framework | Swift Testing (`import Testing`, `@Test`) vs legacy XCTest? |
| Placeholder | Empty `@Test func example()` with template comment only? |
| Target config | Test deployment target matches app? Device family aligned? |
| Testability | Is any logic extractable from views for unit tests? |
| Helpers | Shared fixtures, mocks, or test support folder? |

Red flags:
- Zero assertions in test target
- `IPHONEOS_DEPLOYMENT_TARGET` mismatch between app and tests targets
- No tests planned for core domain logic

## config

Ask:

| Check | Question |
|-------|----------|
| Bundle ID | Still `devplaceholder` or template pattern? |
| Deployment | iOS target matches project rule (26+)? Consistent across targets? |
| Concurrency | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`? `SWIFT_APPROACHABLE_CONCURRENCY`? |
| Platforms | iPhone-only vs iPad? Mac Catalyst? Matches product plan? |
| Signing | Placeholder team or production team on tests only? |
| Info.plist | Generated vs custom keys needed for planned features? |

Red flags:
- App at iOS 26, tests at iOS 17 (unless intentional)
- `PRODUCT_BUNDLE_IDENTIFIER` still placeholder
- Sandbox / entitlements not aligned with planned capabilities (CloudKit, App Groups)

## ui

Ask:

| Check | Question |
|-------|----------|
| Root view | Hello World placeholder or app shell (tabs, nav, empty state)? |
| State | `@Observable` view models ready or no state layer? |
| Navigation | `NavigationStack` + `navigationDestination(for:)` in place? |
| Previews | `#Preview` on main views? |
| SwiftUI hygiene | `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, no legacy patterns? |
| Localization | `Localizable.xcstrings` or hardcoded strings? |

Red flags:
- `Text("Hello, world!")` as primary UI
- `#Playground` block in app target source
- `@StateObject` / `ObservableObject` in greenfield boilerplate

## assets

Ask:

| Check | Question |
|-------|----------|
| App icon | Default empty icon set vs branded? |
| Accent | Default accent color only? |
| Catalog | `Assets.xcassets` structure for future images/colors? |
| Strings | `STRING_CATALOG_GENERATE_SYMBOLS` enabled but no catalog file? |

Red flags:
- No app icon assets before any TestFlight plan
- All user-facing strings inline in Swift

## Cross-domain (all)

When `--area all`, also ask:
- Does the boilerplate encode **one** clear next step for the team?
- Would a new contributor know where to add a feature in under 5 minutes?
- Is anything in the project **actively misleading** about what Zanzar is?
