@testable import SeriesAtlas

@MainActor
final class SearchPeopleUseCaseMock: SearchPeopleUseCaseProtocol {
    enum MockError: Error {
        case forcedFailure
        case closed
        case invocationNotPending(Int)
    }

    private(set) var queries: [String] = []
    private var pending: [Int: CheckedContinuation<[Person], any Error>] = [:]
    private var waiters: [(index: Int, continuation: CheckedContinuation<Void, any Error>)] = []
    private var isClosed = false

    @MainActor
    func execute(query: String) async throws -> [Person] {
        guard !isClosed else { throw MockError.closed }
        let index = queries.count

        // Ignora la cancelación de esta tarea para poder devolver un éxito o error tardío.
        // La prueba comprueba así el descarte del ViewModel, sin ayuda del caso de uso.
        return try await withCheckedThrowingContinuation { continuation in
            pending[index] = continuation
            queries.append(query)
            let ready = waiters.filter { $0.index < queries.count }
            waiters.removeAll { $0.index < queries.count }
            ready.forEach { $0.continuation.resume() }
        }
    }

    func waitForInvocation(_ index: Int) async throws {
        guard !isClosed else { throw MockError.closed }
        guard queries.count <= index else { return }
        try await withCheckedThrowingContinuation { continuation in
            waiters.append((index, continuation))
        }
    }

    func completeInvocation(_ index: Int, with result: Result<[Person], any Error>) throws {
        guard let continuation = pending.removeValue(forKey: index) else {
            throw MockError.invocationNotPending(index)
        }
        continuation.resume(with: result)
    }

    func close() {
        isClosed = true
        let pendingResponses = Array(pending.values)
        let pendingWaiters = waiters
        pending.removeAll()
        waiters.removeAll()
        pendingResponses.forEach { $0.resume(throwing: MockError.closed) }
        pendingWaiters.forEach { $0.continuation.resume(throwing: MockError.closed) }
    }
}
