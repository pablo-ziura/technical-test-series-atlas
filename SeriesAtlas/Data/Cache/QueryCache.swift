import Foundation

actor QueryCache<Value: Sendable> {
    private struct Entry {
        let value: Value
        let expiresAt: Date
    }

    private let now: @Sendable () -> Date
    private var entries: [String: Entry] = [:]

    init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    func value(for query: String) -> Value? {
        let key = normalizedKey(for: query)
        guard let entry = entries[key] else { return nil }
        guard now() < entry.expiresAt else {
            entries[key] = nil
            return nil
        }
        return entry.value
    }

    func insert(_ value: Value, for query: String) throws {
        let key = normalizedKey(for: query)
        let entry = Entry(value: value, expiresAt: now().addingTimeInterval(180))
        // Check inside the actor, after the caller's suspension to reach it.
        try Task.checkCancellation()
        entries[key] = entry
    }

    private func normalizedKey(for query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
