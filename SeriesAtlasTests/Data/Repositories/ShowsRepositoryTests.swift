import Foundation
@testable import SeriesAtlas
import Synchronization
import Testing

@MainActor
final class ShowsRepositoryTests {
    private let time: TestTime
    private let mockShowsService: ShowsServiceMock
    private let showsRepository: ShowsRepository

    init() {
        let time = TestTime()
        self.time = time
        mockShowsService = ShowsServiceMock()
        showsRepository = ShowsRepository(
            showsService: mockShowsService,
            cache: QueryCache(now: time.now)
        )
    }

    @Test
    func testSearchNormalizesCacheKeysAndKeepsQueriesIndependent() async throws {
        let expectedShows = try Show.mockShows()
        mockShowsService.showsToReturn = expectedShows
        let originalQuery = " \nThe  Office\t "

        let firstResult = try await showsRepository.searchShows(query: originalQuery)
        mockShowsService.showsToReturn = []
        let cachedResult = try await showsRepository.searchShows(query: "THE  OFFICE")
        let singleSpaceResult = try await showsRepository.searchShows(query: "The Office")
        let otherResult = try await showsRepository.searchShows(query: "Friends")
        let preservedResult = try await showsRepository.searchShows(query: "the  office")

        #expect(firstResult == expectedShows)
        #expect(cachedResult == expectedShows)
        #expect(singleSpaceResult.isEmpty)
        #expect(otherResult.isEmpty)
        #expect(preservedResult == expectedShows)
        #expect(mockShowsService.searchedQueries == [originalQuery, "The Office", "Friends"])
    }

    @Test(arguments: [180.0, 181.0])
    func testCacheExpiresWithoutExtendingLifetimeOnHits(expiration: TimeInterval) async throws {
        let initialShows = try Show.mockShows()
        let refreshedShows = Array(initialShows.reversed())
        mockShowsService.showsToReturn = initialShows
        _ = try await showsRepository.searchShows(query: "The Office")
        mockShowsService.showsToReturn = refreshedShows

        time.advance(by: 179)
        #expect(try await showsRepository.searchShows(query: "The Office") == initialShows)
        #expect(mockShowsService.searchedQueries.count == 1)

        time.advance(by: expiration - 179)
        #expect(try await showsRepository.searchShows(query: "The Office") == refreshedShows)
        mockShowsService.showsToReturn = []
        time.advance(by: 179)
        #expect(try await showsRepository.searchShows(query: "The Office") == refreshedShows)
        #expect(mockShowsService.searchedQueries.count == 2)
    }

    @Test
    func testCacheLifetimeStartsWhenResponseIsStored() async throws {
        let expectedShows = try Show.mockShows()
        mockShowsService.showsToReturn = expectedShows
        mockShowsService.onSearch = { [time] in time.advance(by: 60) }
        _ = try await showsRepository.searchShows(query: "The Office")
        mockShowsService.onSearch = nil
        mockShowsService.showsToReturn = []

        time.advance(by: 179)
        #expect(try await showsRepository.searchShows(query: "The Office") == expectedShows)
        time.advance(by: 1)
        #expect(try await showsRepository.searchShows(query: "The Office").isEmpty)
        #expect(mockShowsService.searchedQueries.count == 2)
    }

    @Test(arguments: ["Unknown show", ""])
    func testSearchCachesEmptyResults(query: String) async throws {
        #expect(try await showsRepository.searchShows(query: query).isEmpty)
        mockShowsService.showsToReturn = try Show.mockShows()

        #expect(try await showsRepository.searchShows(query: " \n\(query.uppercased())\t ").isEmpty)
        #expect(mockShowsService.searchedQueries == [query])
    }

    @Test(arguments: [false, true])
    func testFailedRefreshPropagatesWithoutReturningOrReplacingExpiredResults(isCancellation: Bool) async throws {
        let initialShows = try Show.mockShows()
        mockShowsService.showsToReturn = initialShows
        _ = try await showsRepository.searchShows(query: "The Office")
        time.advance(by: 180)

        if isCancellation {
            mockShowsService.errorToThrow = CancellationError()
            await #expect(throws: CancellationError.self) {
                try await showsRepository.searchShows(query: "The Office")
            }
        } else {
            mockShowsService.errorToThrow = ShowsServiceMock.MockError.forcedFailure
            await #expect(throws: ShowsServiceMock.MockError.forcedFailure) {
                try await showsRepository.searchShows(query: "The Office")
            }
        }

        mockShowsService.errorToThrow = nil
        let refreshedShows = Array(initialShows.reversed())
        mockShowsService.showsToReturn = refreshedShows
        #expect(try await showsRepository.searchShows(query: "The Office") == refreshedShows)
        #expect(mockShowsService.searchedQueries.count == 3)
    }

    @Test(arguments: [false, true])
    func testAlreadyCancelledSearchDoesNotCallService(hasCachedResults: Bool) async throws {
        mockShowsService.showsToReturn = try Show.mockShows()
        if hasCachedResults {
            _ = try await showsRepository.searchShows(query: "The Office")
        }
        let previousQueries = mockShowsService.searchedQueries
        let task = Task { try await showsRepository.searchShows(query: "The Office") }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockShowsService.searchedQueries == previousQueries)
    }

    @Test
    func testCancellationDuringCacheHitDoesNotReturnResults() async throws {
        let shouldCancel = Mutex(false)
        let cache = QueryCache<[Show]>(now: {
            if shouldCancel.withLock({ $0 }) {
                withUnsafeCurrentTask { $0?.cancel() }
            }
            return Date(timeIntervalSince1970: 0)
        })
        let repository = ShowsRepository(showsService: mockShowsService, cache: cache)
        mockShowsService.showsToReturn = try Show.mockShows()
        _ = try await repository.searchShows(query: "The Office")
        shouldCancel.withLock { $0 = true }

        let task = Task { try await repository.searchShows(query: "The Office") }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockShowsService.searchedQueries == ["The Office"])
    }

    @Test
    func testCancellationDuringStorageDoesNotCacheResults() async throws {
        let shouldCancel = Mutex(false)
        let cache = QueryCache<[Show]>(now: {
            if shouldCancel.withLock({ $0 }) {
                withUnsafeCurrentTask { $0?.cancel() }
            }
            return Date(timeIntervalSince1970: 0)
        })
        let repository = ShowsRepository(showsService: mockShowsService, cache: cache)
        mockShowsService.showsToReturn = try Show.mockShows()
        mockShowsService.onSearch = { shouldCancel.withLock { $0 = true } }

        let task = Task { try await repository.searchShows(query: "The Office") }
        await #expect(throws: CancellationError.self) { try await task.value }
        shouldCancel.withLock { $0 = false }
        mockShowsService.onSearch = nil
        mockShowsService.showsToReturn = []

        #expect(try await repository.searchShows(query: "The Office").isEmpty)
        #expect(mockShowsService.searchedQueries == ["The Office", "The Office"])
    }

    @Test(arguments: [false, true])
    func testCancelledSearchDoesNotCacheLateResponse(isEmpty: Bool) async throws {
        mockShowsService.showsToReturn = isEmpty ? [] : try Show.mockShows()
        var pendingResponse: CheckedContinuation<Void, Never>?
        let task = Task { try await showsRepository.searchShows(query: "The Office") }

        await withCheckedContinuation { started in
            mockShowsService.onSearch = {
                await withCheckedContinuation { response in
                    pendingResponse = response
                    started.resume()
                }
            }
        }
        task.cancel()
        try #require(pendingResponse).resume()
        await #expect(throws: CancellationError.self) { try await task.value }

        mockShowsService.onSearch = nil
        let nextShows = Array(try Show.mockShows().reversed())
        mockShowsService.showsToReturn = nextShows
        #expect(try await showsRepository.searchShows(query: "The Office") == nextShows)
        #expect(mockShowsService.searchedQueries == ["The Office", "The Office"])
    }
}
