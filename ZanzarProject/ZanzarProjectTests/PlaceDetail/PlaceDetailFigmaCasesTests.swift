import Foundation
import Testing
@testable import ZanzarProject

/// The check-in cases from the Figma "Fluxo e erros" catalog: already done (E4), no network (E5), closed (E6).
@MainActor
@Suite("PlaceDetailViewModel Figma cases")
struct PlaceDetailFigmaCasesTests {
    private let opens = Date(timeIntervalSince1970: 1_800_100_000)

    private func makeViewModel(
        detail: PlaceDetail = PlaceDetailFixture.detail(),
        service: MockPlaceDetailService? = nil,
        reminders: FakeOpeningReminderScheduler? = nil,
        queue: PendingCheckInQueue? = nil
    ) -> (PlaceDetailViewModel, MockPlaceDetailService, PendingCheckInQueue) {
        let reminders = reminders ?? FakeOpeningReminderScheduler()
        let service = service ?? MockPlaceDetailService(
            fetchResult: .success(detail),
            checkInResult: .success(PlaceDetailFixture.checkInResult)
        )
        let queue = queue ?? PendingCheckInQueue(
            store: InMemoryPendingCheckInStore(),
            service: service,
            userIDProvider: { "user-1" }
        )
        let viewModel = PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { PlaceDetailFixture.nearbyUserCoordinate },
            service: service,
            pendingRatingStore: InMemoryPendingRatingStore(),
            openingReminders: reminders,
            pendingCheckIns: queue
        )
        return (viewModel, service, queue)
    }

    // MARK: E5 — no network

    @Test("a check-in with no network offers to keep it, instead of showing a system error")
    func offlineWarning() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(URLError(.notConnectedToInternet))
        )
        let (viewModel, _, queue) = makeViewModel(service: service)
        await viewModel.load()

        await viewModel.confirmCheckIn()

        #expect(viewModel.checkInWarning == .offline)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.detail?.hasCheckedIn == false)
        #expect(queue.count == 0)
    }

    @Test("keeping it stores the check-in as the user made it and marks the place pending")
    func keepForLater() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(URLError(.timedOut))
        )
        let (viewModel, _, queue) = makeViewModel(service: service)
        await viewModel.load()
        await viewModel.confirmCheckIn()

        viewModel.keepCheckInForLater()

        #expect(viewModel.checkInWarning == nil)
        #expect(viewModel.isCheckInPending)
        let item = queue.pending.first
        #expect(item?.placeID == PlaceDetailFixture.place.id)
        #expect(item?.userID == "user-1")
        #expect(item?.id == service.checkInCalls.first?.mutationID)
        #expect(item?.checkedInAt == service.checkInDates.first)
        #expect(item?.latitude == PlaceDetailFixture.nearbyUserCoordinate.latitude)
    }

    @Test("trying again after no network reuses the same id and the original time")
    func retryReplaysTheSameCheckIn() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(URLError(.networkConnectionLost))
        )
        let (viewModel, _, _) = makeViewModel(service: service)
        await viewModel.load()
        await viewModel.confirmCheckIn()
        service.checkInResult = .success(PlaceDetailFixture.checkInResult)

        await viewModel.performCheckIn()

        #expect(service.checkInCalls.count == 2)
        #expect(service.checkInCalls[0].mutationID == service.checkInCalls[1].mutationID)
        #expect(service.checkInDates[0] == service.checkInDates[1])
        #expect(viewModel.detail?.hasCheckedIn == true)
    }

    @Test("other failures keep showing their own message, not the offline offer")
    func otherErrorsAreNotOffline() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(APIError.httpStatus(500, message: nil))
        )
        let (viewModel, _, _) = makeViewModel(service: service)
        await viewModel.load()

        await viewModel.confirmCheckIn()

        #expect(viewModel.checkInWarning == nil)
        #expect(viewModel.errorMessage == L10n.string("error.generic.message"))
    }

    // MARK: E4 — already checked in

    @Test("a 409 on check-in says the user already passed by")
    func conflictShowsTheAlreadyAlert() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(APIError.httpStatus(409, message: nil))
        )
        let (viewModel, _, _) = makeViewModel(service: service)
        await viewModel.load()

        await viewModel.confirmCheckIn()

        #expect(viewModel.showsAlreadyCheckedInAlert)
        #expect(viewModel.detail?.hasCheckedIn == true)
    }

    @Test("tapping the done button shows when the check-in was made")
    func alreadyMessageHasTheDate() async {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let detail = PlaceDetailFixture.detail(hasCheckedIn: true, checkedInAt: date)
        let (viewModel, _, _) = makeViewModel(detail: detail)
        await viewModel.load()

        viewModel.showAlreadyCheckedIn()

        #expect(viewModel.showsAlreadyCheckedInAlert)
        #expect(viewModel.alreadyCheckedInMessage == L10n.string(
            "placeDetail.alreadyCheckedIn.messageWithDate",
            date.formatted(date: .numeric, time: .omitted),
            date.formatted(date: .omitted, time: .shortened)
        ))
    }

    @Test("without the date the message still makes sense, and the alert only shows after a check-in")
    func alreadyMessageWithoutDate() async {
        let (viewModel, _, _) = makeViewModel(detail: PlaceDetailFixture.detail(hasCheckedIn: true))
        await viewModel.load()
        #expect(viewModel.alreadyCheckedInMessage == L10n.string("placeDetail.alreadyCheckedIn.message"))

        let (fresh, _, _) = makeViewModel()
        await fresh.load()
        fresh.showAlreadyCheckedIn()
        #expect(!fresh.showsAlreadyCheckedInAlert)
    }

    // MARK: E6 — closed

    @Test("the reminder is scheduled for the opening time and can be cancelled")
    func reminderToggle() async {
        let reminders = FakeOpeningReminderScheduler()
        let detail = PlaceDetailFixture.detail(isOpen: false, opensAt: opens)
        let (viewModel, _, _) = makeViewModel(detail: detail, reminders: reminders)
        await viewModel.load()
        #expect(!viewModel.hasOpeningReminder)

        #expect(await viewModel.toggleOpeningReminder() == .scheduled)
        #expect(viewModel.hasOpeningReminder)
        #expect(reminders.scheduled[PlaceDetailFixture.place.id] == opens)

        #expect(await viewModel.toggleOpeningReminder() == .cancelled)
        #expect(!viewModel.hasOpeningReminder)
        #expect(reminders.scheduled.isEmpty)
    }

    @Test("without permission nothing is scheduled and the user is told")
    func reminderNeedsPermission() async {
        let reminders = FakeOpeningReminderScheduler()
        reminders.allowsNotifications = false
        let detail = PlaceDetailFixture.detail(isOpen: false, opensAt: opens)
        let (viewModel, _, _) = makeViewModel(detail: detail, reminders: reminders)
        await viewModel.load()

        #expect(await viewModel.toggleOpeningReminder() == .permissionDenied)
        #expect(!viewModel.hasOpeningReminder)
    }

    @Test("a reminder that was already scheduled shows as set when the place is opened again")
    func reminderIsRemembered() async {
        let reminders = FakeOpeningReminderScheduler()
        reminders.scheduled[PlaceDetailFixture.place.id] = opens
        let detail = PlaceDetailFixture.detail(isOpen: false, opensAt: opens)
        let (viewModel, _, _) = makeViewModel(detail: detail, reminders: reminders)

        await viewModel.load()

        #expect(viewModel.hasOpeningReminder)
    }

    @Test("without an opening time there is nothing to remind")
    func noOpeningTime() async {
        let detail = PlaceDetailFixture.detail(isOpen: false, opensAt: nil)
        let (viewModel, _, _) = makeViewModel(detail: detail)
        await viewModel.load()

        #expect(await viewModel.toggleOpeningReminder() == nil)
    }

    @Test("a closed place still lets the user check in")
    func closedStillAllowsCheckIn() async {
        let detail = PlaceDetailFixture.detail(isOpen: false, opensAt: opens)
        let (viewModel, service, _) = makeViewModel(detail: detail)
        await viewModel.load()

        await viewModel.requestCheckIn()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.count == 1)
        #expect(viewModel.detail?.hasCheckedIn == true)
    }
}
