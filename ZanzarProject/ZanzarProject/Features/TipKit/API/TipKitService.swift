import Foundation
import TipKit

/// Protocol for configuring and managing TipKit tips across the app.
protocol TipKitServicing: Sendable {
    /// Configures TipKit with the app's tips and display rules.
    func configure() async throws
    /// Resets all tip display state (useful for testing or "show tutorial again").
    func resetAllTips() async
    /// Gets a tip by its identifier.
    func tip(for identifier: String) -> (any Tip)?
}

/// Concrete implementation using Apple's TipKit framework.
final class TipKitService: TipKitServicing {
    static let shared = TipKitService()
    
    /// All tips defined for the app, keyed by identifier.
    private let tips: [String: any Tip] = [
        // Onboarding / Welcome
        "welcome.createAccount": WelcomeCreateAccountTip(),
        "welcome.signIn": WelcomeSignInTip(),
        
        // Discover / Map tab
        "discover.mapPins": DiscoverMapPinsTip(),
        "discover.filterButton": DiscoverFilterTip(),
        "discover.searchPlaces": DiscoverSearchTip(),
        "discover.userLocation": DiscoverUserLocationTip(),
        
        // Check-in / Itinerary tab
        "checkIn.createItinerary": CheckInCreateItineraryTip(),
        "checkIn.startItinerary": CheckInStartItineraryTip(),
        "checkIn.checkInPlace": CheckInPlaceTip(),
        "checkIn.proximityAlerts": CheckInProximityAlertsTip(),
        
        // Profile tab
        "profile.myPhotos": ProfileMyPhotosTip(),
        "profile.mySuggestions": ProfileMySuggestionsTip(),
        "profile.editAvatar": ProfileEditAvatarTip(),
        "profile.settings": ProfileSettingsTip(),
        
        // Place Detail
        "placeDetail.savePlace": PlaceDetailSaveTip(),
        "placeDetail.checkIn": PlaceDetailCheckInTip(),
        "placeDetail.addPhoto": PlaceDetailAddPhotoTip(),
        "placeDetail.share": PlaceDetailShareTip(),
        "placeDetail.directions": PlaceDetailDirectionsTip(),
        
        // Onboarding flow
        "onboarding.avatarEditor": OnboardingAvatarEditorTip(),
        "onboarding.passportIntro": OnboardingPassportIntroTip(),
        "onboarding.notificationPermission": OnboardingNotificationTip(),
        
        // User Photos
        "userPhotos.takePhoto": UserPhotosTakePhotoTip(),
        "userPhotos.uploadPhoto": UserPhotosUploadTip(),
        "userPhotos.photoStatus": UserPhotosStatusTip(),
        
        // Place Suggestion
        "placeSuggestion.suggestPlace": PlaceSuggestionTip(),
        
        // Proximity Alerts
        "proximityAlerts.enable": ProximityAlertsEnableTip(),
        "proximityAlerts.customize": ProximityAlertsCustomizeTip(),
    ]
    
    private init() {}
    
    func configure() async throws {
        // Configure TipKit with default datastore (UserDefaults-based)
        try Tips.configure([
            .datastoreLocation(.applicationDefault)
        ])
        
        // All tips are automatically registered when their TipView/.popoverTip() is shown
        // No need to pre-register them here
    }
    
    func resetAllTips() async {
        try? Tips.resetDatastore()
        try? await configure()
    }
    
    func tip(for identifier: String) -> (any Tip)? {
        return tips[identifier]
    }
    
    /// Marks a tip as seen by updating its parameter.
    /// Call this when the user completes the action the tip teaches.
    func markTipAsSeen(_ identifier: String) {
        // The parameters are static on each tip type, so we can't easily update them generically.
        // Instead, each tip's parameter gets updated when the relevant action happens in the app.
        // This method exists for API completeness but the actual marking happens in each feature.
    }
}

// MARK: - Tip Definitions

// Welcome Tips
struct WelcomeCreateAccountTip: Tip {
    var title: Text { Text("tipkit.welcome.createAccount.title") }
    var message: Text? { Text("tipkit.welcome.createAccount.message") }
    var image: Image? { Image(systemName: "person.badge.plus") }
    var identifier: String { "welcome.createAccount" }
    var rules: [Rule] {
        #Rule(Self.$hasSeenWelcome) { $0 == false }
    }
    @Parameter static var hasSeenWelcome: Bool = false
}

struct WelcomeSignInTip: Tip {
    var title: Text { Text("tipkit.welcome.signIn.title") }
    var message: Text? { Text("tipkit.welcome.signIn.message") }
    var image: Image? { Image(systemName: "arrow.right.square") }
    var identifier: String { "welcome.signIn" }
    var rules: [Rule] {
        #Rule(Self.$hasSeenWelcome) { $0 == false }
    }
    @Parameter static var hasSeenWelcome: Bool = false
}

// Discover / Map Tips
struct DiscoverMapPinsTip: Tip {
    var title: Text { Text("tipkit.discover.mapPins.title") }
    var message: Text? { Text("tipkit.discover.mapPins.message") }
    var image: Image? { Image(systemName: "mappin.and.ellipse") }
    var identifier: String { "discover.mapPins" }
    var rules: [Rule] {
        #Rule(Self.$hasUsedDiscover) { $0 == false }
    }
    @Parameter static var hasUsedDiscover: Bool = false
}

struct DiscoverFilterTip: Tip {
    var title: Text { Text("tipkit.discover.filter.title") }
    var message: Text? { Text("tipkit.discover.filter.message") }
    var image: Image? { Image(systemName: "line.3.horizontal.decrease.circle") }
    var identifier: String { "discover.filterButton" }
    var rules: [Rule] {
        #Rule(Self.$hasUsedDiscover) { $0 == false }
    }
    @Parameter static var hasUsedDiscover: Bool = false
}

struct DiscoverSearchTip: Tip {
    var title: Text { Text("tipkit.discover.search.title") }
    var message: Text? { Text("tipkit.discover.search.message") }
    var image: Image? { Image(systemName: "magnifyingglass") }
    var identifier: String { "discover.searchPlaces" }
    var rules: [Rule] {
        #Rule(Self.$hasUsedDiscover) { $0 == false }
    }
    @Parameter static var hasUsedDiscover: Bool = false
}

struct DiscoverUserLocationTip: Tip {
    var title: Text { Text("tipkit.discover.userLocation.title") }
    var message: Text? { Text("tipkit.discover.userLocation.message") }
    var image: Image? { Image(systemName: "location.fill") }
    var identifier: String { "discover.userLocation" }
    var rules: [Rule] {
        #Rule(Self.$hasUsedDiscover) { $0 == false }
    }
    @Parameter static var hasUsedDiscover: Bool = false
}

// Check-in / Itinerary Tips
struct CheckInCreateItineraryTip: Tip {
    var title: Text { Text("tipkit.checkIn.createItinerary.title") }
    var message: Text? { Text("tipkit.checkIn.createItinerary.message") }
    var image: Image? { Image(systemName: "plus.circle") }
    var identifier: String { "checkIn.createItinerary" }
    var rules: [Rule] {
        #Rule(Self.$hasCreatedItinerary) { $0 == false }
    }
    @Parameter static var hasCreatedItinerary: Bool = false
}

struct CheckInStartItineraryTip: Tip {
    var title: Text { Text("tipkit.checkIn.startItinerary.title") }
    var message: Text? { Text("tipkit.checkIn.startItinerary.message") }
    var image: Image? { Image(systemName: "play.circle") }
    var identifier: String { "checkIn.startItinerary" }
    var rules: [Rule] {
        #Rule(Self.$hasCreatedItinerary) { $0 == true }
        #Rule(Self.$hasStartedItinerary) { $0 == false }
    }
    @Parameter static var hasCreatedItinerary: Bool = false
    @Parameter static var hasStartedItinerary: Bool = false
}

struct CheckInPlaceTip: Tip {
    var title: Text { Text("tipkit.checkIn.checkInPlace.title") }
    var message: Text? { Text("tipkit.checkIn.checkInPlace.message") }
    var image: Image? { Image(systemName: "checkmark.circle") }
    var identifier: String { "checkIn.checkInPlace" }
    var rules: [Rule] {
        #Rule(Self.$hasStartedItinerary) { $0 == true }
        #Rule(Self.$hasCheckedIn) { $0 == false }
    }
    @Parameter static var hasStartedItinerary: Bool = false
    @Parameter static var hasCheckedIn: Bool = false
}

struct CheckInProximityAlertsTip: Tip {
    var title: Text { Text("tipkit.checkIn.proximityAlerts.title") }
    var message: Text? { Text("tipkit.checkIn.proximityAlerts.message") }
    var image: Image? { Image(systemName: "bell.badge") }
    var identifier: String { "checkIn.proximityAlerts" }
    var rules: [Rule] {
        #Rule(Self.$hasStartedItinerary) { $0 == true }
    }
    @Parameter static var hasStartedItinerary: Bool = false
}

// Profile Tips
struct ProfileMyPhotosTip: Tip {
    var title: Text { Text("tipkit.profile.myPhotos.title") }
    var message: Text? { Text("tipkit.profile.myPhotos.message") }
    var image: Image? { Image(systemName: "photo.stack") }
    var identifier: String { "profile.myPhotos" }
    var rules: [Rule] {
        #Rule(Self.$hasVisitedProfile) { $0 == false }
    }
    @Parameter static var hasVisitedProfile: Bool = false
}

struct ProfileMySuggestionsTip: Tip {
    var title: Text { Text("tipkit.profile.mySuggestions.title") }
    var message: Text? { Text("tipkit.profile.mySuggestions.message") }
    var image: Image? { Image(systemName: "lightbulb") }
    var identifier: String { "profile.mySuggestions" }
    var rules: [Rule] {
        #Rule(Self.$hasVisitedProfile) { $0 == false }
    }
    @Parameter static var hasVisitedProfile: Bool = false
}

struct ProfileEditAvatarTip: Tip {
    var title: Text { Text("tipkit.profile.editAvatar.title") }
    var message: Text? { Text("tipkit.profile.editAvatar.message") }
    var image: Image? { Image(systemName: "person.crop.circle.badge.plus") }
    var identifier: String { "profile.editAvatar" }
    var rules: [Rule] {
        #Rule(Self.$hasVisitedProfile) { $0 == false }
    }
    @Parameter static var hasVisitedProfile: Bool = false
}

struct ProfileSettingsTip: Tip {
    var title: Text { Text("tipkit.profile.settings.title") }
    var message: Text? { Text("tipkit.profile.settings.message") }
    var image: Image? { Image(systemName: "gearshape") }
    var identifier: String { "profile.settings" }
    var rules: [Rule] {
        #Rule(Self.$hasVisitedProfile) { $0 == false }
    }
    @Parameter static var hasVisitedProfile: Bool = false
}

// Place Detail Tips
struct PlaceDetailSaveTip: Tip {
    var title: Text { Text("tipkit.placeDetail.save.title") }
    var message: Text? { Text("tipkit.placeDetail.save.message") }
    var image: Image? { Image(systemName: "bookmark") }
    var identifier: String { "placeDetail.savePlace" }
    var rules: [Rule] {
        #Rule(Self.$hasViewedPlaceDetail) { $0 == false }
    }
    @Parameter static var hasViewedPlaceDetail: Bool = false
}

struct PlaceDetailCheckInTip: Tip {
    var title: Text { Text("tipkit.placeDetail.checkIn.title") }
    var message: Text? { Text("tipkit.placeDetail.checkIn.message") }
    var image: Image? { Image(systemName: "checkmark.circle.fill") }
    var identifier: String { "placeDetail.checkIn" }
    var rules: [Rule] {
        #Rule(Self.$hasViewedPlaceDetail) { $0 == false }
    }
    @Parameter static var hasViewedPlaceDetail: Bool = false
}

struct PlaceDetailAddPhotoTip: Tip {
    var title: Text { Text("tipkit.placeDetail.addPhoto.title") }
    var message: Text? { Text("tipkit.placeDetail.addPhoto.message") }
    var image: Image? { Image(systemName: "camera") }
    var identifier: String { "placeDetail.addPhoto" }
    var rules: [Rule] {
        #Rule(Self.$hasViewedPlaceDetail) { $0 == false }
    }
    @Parameter static var hasViewedPlaceDetail: Bool = false
}

struct PlaceDetailShareTip: Tip {
    var title: Text { Text("tipkit.placeDetail.share.title") }
    var message: Text? { Text("tipkit.placeDetail.share.message") }
    var image: Image? { Image(systemName: "square.and.arrow.up") }
    var identifier: String { "placeDetail.share" }
    var rules: [Rule] {
        #Rule(Self.$hasViewedPlaceDetail) { $0 == false }
    }
    @Parameter static var hasViewedPlaceDetail: Bool = false
}

struct PlaceDetailDirectionsTip: Tip {
    var title: Text { Text("tipkit.placeDetail.directions.title") }
    var message: Text? { Text("tipkit.placeDetail.directions.message") }
    var image: Image? { Image(systemName: "arrow.triangle.turn.up.right.diamond") }
    var identifier: String { "placeDetail.directions" }
    var rules: [Rule] {
        #Rule(Self.$hasViewedPlaceDetail) { $0 == false }
    }
    @Parameter static var hasViewedPlaceDetail: Bool = false
}

// Onboarding Tips
struct OnboardingAvatarEditorTip: Tip {
    var title: Text { Text("tipkit.onboarding.avatarEditor.title") }
    var message: Text? { Text("tipkit.onboarding.avatarEditor.message") }
    var image: Image? { Image(systemName: "paintbrush") }
    var identifier: String { "onboarding.avatarEditor" }
    var rules: [Rule] {
        #Rule(Self.$isOnboarding) { $0 == true }
    }
    @Parameter static var isOnboarding: Bool = true
}

struct OnboardingPassportIntroTip: Tip {
    var title: Text { Text("tipkit.onboarding.passportIntro.title") }
    var message: Text? { Text("tipkit.onboarding.passportIntro.message") }
    var image: Image? { Image(systemName: "ticket") }
    var identifier: String { "onboarding.passportIntro" }
    var rules: [Rule] {
        #Rule(Self.$isOnboarding) { $0 == true }
    }
    @Parameter static var isOnboarding: Bool = true
}

struct OnboardingNotificationTip: Tip {
    var title: Text { Text("tipkit.onboarding.notification.title") }
    var message: Text? { Text("tipkit.onboarding.notification.message") }
    var image: Image? { Image(systemName: "bell") }
    var identifier: String { "onboarding.notificationPermission" }
    var rules: [Rule] {
        #Rule(Self.$isOnboarding) { $0 == true }
    }
    @Parameter static var isOnboarding: Bool = true
}

// User Photos Tips
struct UserPhotosTakePhotoTip: Tip {
    var title: Text { Text("tipkit.userPhotos.takePhoto.title") }
    var message: Text? { Text("tipkit.userPhotos.takePhoto.message") }
    var image: Image? { Image(systemName: "camera.viewfinder") }
    var identifier: String { "userPhotos.takePhoto" }
    var rules: [Rule] {
        #Rule(Self.$hasOpenedMyPhotos) { $0 == false }
    }
    @Parameter static var hasOpenedMyPhotos: Bool = false
}

struct UserPhotosUploadTip: Tip {
    var title: Text { Text("tipkit.userPhotos.upload.title") }
    var message: Text? { Text("tipkit.userPhotos.upload.message") }
    var image: Image? { Image(systemName: "icloud.and.arrow.up") }
    var identifier: String { "userPhotos.uploadPhoto" }
    var rules: [Rule] {
        #Rule(Self.$hasTakenPhoto) { $0 == true }
        #Rule(Self.$hasUploadedPhoto) { $0 == false }
    }
    @Parameter static var hasTakenPhoto: Bool = false
    @Parameter static var hasUploadedPhoto: Bool = false
}

struct UserPhotosStatusTip: Tip {
    var title: Text { Text("tipkit.userPhotos.status.title") }
    var message: Text? { Text("tipkit.userPhotos.status.message") }
    var image: Image? { Image(systemName: "clock.badge.checkmark") }
    var identifier: String { "userPhotos.photoStatus" }
    var rules: [Rule] {
        #Rule(Self.$hasUploadedPhoto) { $0 == true }
    }
    @Parameter static var hasUploadedPhoto: Bool = false
}

// Place Suggestion Tip
struct PlaceSuggestionTip: Tip {
    var title: Text { Text("tipkit.placeSuggestion.suggest.title") }
    var message: Text? { Text("tipkit.placeSuggestion.suggest.message") }
    var image: Image? { Image(systemName: "plus.message") }
    var identifier: String { "placeSuggestion.suggestPlace" }
    var rules: [Rule] {
        #Rule(Self.$hasUsedDiscover) { $0 == true }
    }
    @Parameter static var hasUsedDiscover: Bool = false
}

// Proximity Alerts Tips
struct ProximityAlertsEnableTip: Tip {
    var title: Text { Text("tipkit.proximityAlerts.enable.title") }
    var message: Text? { Text("tipkit.proximityAlerts.enable.message") }
    var image: Image? { Image(systemName: "location.badge.plus") }
    var identifier: String { "proximityAlerts.enable" }
    var rules: [Rule] {
        #Rule(Self.$hasStartedItinerary) { $0 == true }
    }
    @Parameter static var hasStartedItinerary: Bool = false
}

struct ProximityAlertsCustomizeTip: Tip {
    var title: Text { Text("tipkit.proximityAlerts.customize.title") }
    var message: Text? { Text("tipkit.proximityAlerts.customize.message") }
    var image: Image? { Image(systemName: "slider.horizontal.3") }
    var identifier: String { "proximityAlerts.customize" }
    var rules: [Rule] {
        #Rule(Self.$hasEnabledAlerts) { $0 == true }
    }
    @Parameter static var hasEnabledAlerts: Bool = false
}