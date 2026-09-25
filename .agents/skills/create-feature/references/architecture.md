# ZanzarProject MVVM-C Architecture

## Data flow

```
View <-> ViewModel <-> Service (protocol) <-> NetworkClient (protocol, shared)
```

- **View**: SwiftUI struct. Owns a `@State private var viewModel`. Reads `AppCoordinator` via `@Environment` for navigation — never builds its own `NavigationStack` logic or talks to a Service directly.
- **ViewModel**: `@Observable final class`. Owns all state and business logic for the feature. Depends on the feature's `Servicing` protocol (never a concrete `URLSessionNetworkClient` and never the feature's own network types). Default-initializes the concrete Service in `init(service: Servicing = ConcreteService())` so previews/call sites don't need to pass one, but tests inject a mock.
- **Service**: one per feature, in `API/<Feature>Service.swift`. Defines a `<Feature>Servicing` protocol + concrete `<Feature>Service` implementation, plus the wire-format `Request`/`Response` structs. Calls the shared `NetworkClient`, never `URLSession` directly.
- **NetworkClient**: one shared instance for the whole app, at `Utils/NetworkClient.swift`. Every feature's Service depends on it through the `NetworkClient` protocol, not the concrete `URLSessionNetworkClient` (except as a default-argument value, same pattern as Service above).

## Folder contract

```
ZanzarProject/ZanzarProject/
  App/                          ContentView.swift, MyApp.swift (@main)
                                Components/         app-shell UI only (tabs, placeholders)
  Features/
    Shared/                     cross-feature code — NOT a navigable feature
      Views/
        Components/
          <Domain>/             e.g. Auth/ — UI reused by 2+ features
      Utils/                    domain helpers shared across features
    <FeatureName>/
      API/
        <FeatureName>Service.swift     protocol + impl + Request/Response
      Models/
        <FeatureName>.swift            domain model(s) the View/ViewModel use
      Views/
        <FeatureName>View.swift
        Components/                   subviews used by this feature only
      ViewModels/
        <FeatureName>ViewModel.swift
  Coordinator/
    AppCoordinator.swift         @Observable, owns NavigationPath + sheet/cover state
    Routes.swift                 Route / Sheet / FullScreenCover enums
  Extensions/                    cross-feature Swift/SwiftUI extensions
  Utils/
    NetworkClient.swift          app-wide infrastructure (not feature-domain code)
  Resources/
    Assets.xcassets               images, colors, icons
    Localizable.xcstrings         all user-facing strings, en + pt-BR
ZanzarProjectTests/<FeatureName>/
  <FeatureName>ViewModelTests.swift
```

`<FeatureName>` is always PascalCase and descriptive (`IssueReport`, not `Issue` or `Report1`). It names the folder, the View, the ViewModel, the Service, and the domain Model consistently — grep for the feature name and every layer should show up.

## When to use Shared vs feature Components

| Location | Use when |
|----------|----------|
| `Features/<Feature>/Views/Components/` | The subview is used **only** inside that feature |
| `Features/Shared/Views/Components/<Domain>/` | The subview is reused by **two or more** features (e.g. `Auth/` for SignUp + Login) |
| `Features/Shared/Utils/` | Validation, formatting, or mapping logic shared across features in the same domain |
| `App/Components/` | App **shell** UI only — tab placeholders, root chrome — never feature-flow screens |
| `Utils/` (root) | App-wide infrastructure (`NetworkClient`, `AppLanguage`) — not feature-domain code |

`Features/Shared/` is a transversal folder, not a feature: it has no Service, ViewModel, Route, or API layer.

## Why the layers don't collapse

Ask: if the API contract changes, does the View need to change? It shouldn't — only the Service's `Request`/`Response` and the mapping in the ViewModel change. That's the reason the Service protocol and the domain Model (in `Models/`) are separate from the wire-format structs (in `API/`): the domain model is what the View renders, the wire structs are what the network sends/receives, and the ViewModel is the only place that maps between them.

## Domain Model vs Request/Response

- `Models/<FeatureName>.swift` — what the View and ViewModel work with. Stable, UI-shaped.
- `API/<FeatureName>Service.swift`'s `Request`/`Response` structs — exactly what the wire format needs (`Codable` keys, optional fields the backend sends, etc). These can be uglier than the domain model; that ugliness is exactly what the Service/mapping layer exists to hide.

If a feature's response maps 1:1 to what the View needs, it's still worth keeping both — the domain model is what stays stable when the backend changes a field name.

## Strings are never hardcoded

Every string a View or Component renders is a lookup key into
`Resources/Localizable.xcstrings`, translated into English (US) and Brazilian
Portuguese — not a string literal typed straight into the view. See
references/localization.md for the key convention and the script that
maintains the catalog.
