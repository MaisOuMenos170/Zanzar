/// Kept apart from `PlaceSuggestionOutcome` because the model is also compiled into the share extension,
/// which has no `ToastStyle`.
extension PlaceSuggestionOutcome {
    var toastStyle: ToastStyle {
        isGoodNews ? .positive : .negative
    }
}
