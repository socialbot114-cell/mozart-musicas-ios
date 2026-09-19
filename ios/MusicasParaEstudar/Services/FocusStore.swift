import Foundation
import Combine

@MainActor
final class FocusStore: ObservableObject {
    @Published private(set) var completedMinutes: Int
    @Published private(set) var sessions: Int
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedMinutes = defaults.integer(forKey: "focus.completedMinutes")
        sessions = defaults.integer(forKey: "focus.sessions")
    }

    func record(minutes: Int) {
        completedMinutes += minutes
        sessions += 1
        defaults.set(completedMinutes, forKey: "focus.completedMinutes")
        defaults.set(sessions, forKey: "focus.sessions")
    }
}
