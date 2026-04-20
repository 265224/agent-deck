import Foundation

/// Non-commercial local builds do not check for or install upstream updates.
@MainActor
@Observable
final class UpdateChecker: NSObject {
    override init() {
        super.init()
    }

    func startIfNeeded() {
    }
}
