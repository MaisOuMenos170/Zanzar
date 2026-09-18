# Zanzar

App Structure

```swift
ZanzarProject/ZanzarProject/
  App/                          ContentView.swift, MyApp.swift (@main)
  Features/<FeatureName>/
    API/
      <FeatureName>Service.swift     protocol + impl + Request/Response
    Models/
      <FeatureName>.swift            domain model(s) the View/ViewModel use
    Views/
      <FeatureName>View.swift
      Components/                   extracted subviews for this feature only
    ViewModels/
      <FeatureName>ViewModel.swift
  Coordinator/
    AppCoordinator.swift         @Observable, owns NavigationPath + sheet/cover state
    Routes.swift                 Route / Sheet / FullScreenCover enums
  Extensions/                    cross-feature Swift/SwiftUI extensions
  Utils/
    NetworkClient.swift          the one shared network client
  Resources/
    Assets.xcassets               images, colors, icons
    Localizable.xcstrings         all user-facing strings, en + pt-BR
ZanzarProjectTests/<FeatureName>/
  <FeatureName>ViewModelTests.swift
```

Database
<img width="4394" height="3461" alt="Database" src="https://github.com/user-attachments/assets/a43711c3-a14e-4cfe-bc80-4c60740045f2" />
