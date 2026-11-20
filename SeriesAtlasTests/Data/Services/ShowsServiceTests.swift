import Foundation
@testable import SeriesAtlas
import SeriesAtlasNetwork
import Testing

@MainActor
final class ShowsServiceTests {
    private let mockNetworkClient: NetworkClientMock
    private let showsService: ShowsService

    init() {
        mockNetworkClient = NetworkClientMock()
        showsService = ShowsService(networkClient: mockNetworkClient)
    }

    @Test
    func testSearchShowsMapsResponseAndPreservesOrder() async throws {
        mockNetworkClient.dataToReturn = ShowsResponseFixture.complete

        let result = try await showsService.searchShows(query: "The Office & friends")

        #expect(result.map(\.id) == [526, 525])
        let show = try #require(result.first)
        #expect(show.name == "The Office")
        #expect(show.summary == "The Office & friends.\nCafé épisodes.")
        #expect(show.genres == ["Comedy"])
        #expect(show.language == "English")
        #expect(show.rating == 8.5)
        #expect(show.imageURL?.absoluteString == "https://example.com/office.jpg")
        #expect(show.tvmazeURL.absoluteString == "https://www.tvmaze.com/shows/526/the-office")
        let expectedOptionalShow = try #require(Show.mockShows().last)
        #expect(result.last == expectedOptionalShow)
        #expect(mockNetworkClient.endpoints == ["search/shows"])
        #expect(mockNetworkClient.params == ["q": "The Office & friends"])
    }

    @Test(arguments: ShowsResponseFixture.optionalFields)
    func testSearchShowsMapsMissingAndEmptyOptionalFields(data: Data) async throws {
        mockNetworkClient.dataToReturn = data

        let show = try #require(try await showsService.searchShows(query: "The Office").first)

        #expect(show.summary == nil)
        #expect(show.genres.isEmpty)
        #expect(show.language == nil)
        #expect(show.rating == nil)
        #expect(show.imageURL == nil)
    }

    @Test(arguments: ShowsResponseFixture.fallbackImages)
    func testSearchShowsUsesOriginalImageAsFallback(data: Data) async throws {
        mockNetworkClient.dataToReturn = data

        let show = try #require(try await showsService.searchShows(query: "The Office").first)

        #expect(show.imageURL?.absoluteString == "https://example.com/original.jpg")
    }

    @Test
    func testSearchShowsWithoutResults() async throws {
        mockNetworkClient.dataToReturn = ShowsResponseFixture.empty

        let result = try await showsService.searchShows(query: "Unknown show")

        #expect(result.isEmpty)
    }

    @Test(arguments: ShowsResponseFixture.missingRequiredFields + [ShowsResponseFixture.malformedJSON])
    func testSearchShowsPropagatesDecodingError(data: Data) async {
        mockNetworkClient.dataToReturn = data

        await #expect(throws: DecodingError.self) {
            try await showsService.searchShows(query: "The Office")
        }
    }

    @Test
    func testSearchShowsRejectsInvalidRequiredURL() async {
        mockNetworkClient.dataToReturn = ShowsResponseFixture.invalidShowURL

        await #expect(throws: ShowMappingError.invalidShowURL) {
            try await showsService.searchShows(query: "The Office")
        }
    }

    @Test
    func testSearchShowsPropagatesNetworkError() async {
        mockNetworkClient.errorToThrow = NetworkError.httpStatus(503)

        await #expect(throws: NetworkError.httpStatus(503)) {
            try await showsService.searchShows(query: "The Office")
        }
    }

    @Test
    func testSearchShowsPreservesCancellation() async {
        mockNetworkClient.errorToThrow = CancellationError()

        await #expect(throws: CancellationError.self) {
            try await showsService.searchShows(query: "The Office")
        }
    }

    @Test(arguments: [ShowsResponseFixture.empty, ShowsResponseFixture.complete])
    func testSearchShowsDiscardsResponseAfterCancellation(data: Data) async {
        mockNetworkClient.dataToReturn = data
        let task = Task { try await showsService.searchShows(query: "The Office") }
        mockNetworkClient.onGet = { task.cancel() }
        defer { mockNetworkClient.onGet = nil }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockNetworkClient.endpoints == ["search/shows"])
    }

    @Test
    func testUseCaseSearchesThroughData() async throws {
        mockNetworkClient.dataToReturn = ShowsResponseFixture.complete
        let repository = ShowsRepository(showsService: showsService)
        let useCase = SearchShowsUseCase(showsRepository: repository)

        let result = try await useCase.execute(query: " \nThe Office\t ")

        #expect(result.map(\.id) == [526, 525])
        #expect(mockNetworkClient.endpoints == ["search/shows"])
        #expect(mockNetworkClient.params == ["q": " \nThe Office\t "])
    }
}
