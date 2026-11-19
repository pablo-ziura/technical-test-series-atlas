import Foundation
@testable import SeriesAtlasNetwork

actor HTTPTransportStub: HTTPTransport {
    let result: Result<(Data, URLResponse), any Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<(Data, URLResponse), any Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        return try result.get()
    }
}

actor ControlledHTTPTransport: HTTPTransport {
    struct Request: Identifiable, Sendable {
        let id: Int
        let request: URLRequest
    }

    enum Failure: Error {
        case closed
        case requestNotPending(Request.ID)
        case timedOut
    }

    enum CancellationBehavior: Sendable {
        case cooperative
        case ignoring
    }

    private let cancellationBehavior: CancellationBehavior
    private var requests: [Request] = []
    private var nextRequestID = 0
    private var pending: [Request.ID: CheckedContinuation<(Data, URLResponse), any Error>] = [:]
    private var waiters: [(count: Int, continuation: CheckedContinuation<[Request], any Error>)] = []
    private(set) var closedReason: Failure?
    private(set) var cancelledCount = 0

    init(cancellationBehavior: CancellationBehavior) {
        self.cancellationBehavior = cancellationBehavior
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try checkOpen()
        let identifier = nextRequestID
        nextRequestID += 1

        switch cancellationBehavior {
        case .cooperative:
            return try await withTaskCancellationHandler {
                try await suspend(request: request, identifier: identifier)
            } onCancel: {
                Task { await self.cancel(identifier: identifier) }
            }
        case .ignoring:
            return try await suspend(request: request, identifier: identifier)
        }
    }

    func waitUntilRequested(count: Int = 1) async throws -> [Request] {
        try checkOpen()
        guard requests.count < count else { return Array(requests.prefix(count)) }
        return try await withCheckedThrowingContinuation { waiters.append((count, $0)) }
    }

    func complete(id: Request.ID, with result: Result<(Data, URLResponse), any Error>) throws {
        try checkOpen()
        guard let continuation = pending.removeValue(forKey: id) else {
            throw Failure.requestNotPending(id)
        }
        continuation.resume(with: result)
    }

    func close(throwing reason: Failure = .closed) {
        guard closedReason == nil else { return }
        closedReason = reason
        let pendingRequests = Array(pending.values)
        let waitingRequests = waiters
        pending.removeAll()
        waiters.removeAll()
        pendingRequests.forEach { $0.resume(throwing: reason) }
        waitingRequests.forEach { $0.continuation.resume(throwing: reason) }
    }

    var pendingCount: Int { pending.count }

    private func suspend(request: URLRequest, identifier: Request.ID) async throws -> (Data, URLResponse) {
        try checkOpen()
        if case .cooperative = cancellationBehavior {
            try Task.checkCancellation()
        }
        return try await withCheckedThrowingContinuation { continuation in
            pending[identifier] = continuation
            requests.append(Request(id: identifier, request: request))
            let ready = waiters.filter { $0.count <= requests.count }
            waiters.removeAll { $0.count <= requests.count }
            ready.forEach { $0.continuation.resume(returning: Array(requests.prefix($0.count))) }
        }
    }

    private func checkOpen() throws {
        if let closedReason { throw closedReason }
    }

    private func cancel(identifier: Request.ID) {
        guard let continuation = pending.removeValue(forKey: identifier) else { return }
        cancelledCount += 1
        continuation.resume(throwing: CancellationError())
    }
}

actor StartGate {
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}
