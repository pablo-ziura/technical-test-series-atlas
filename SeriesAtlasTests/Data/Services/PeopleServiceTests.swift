import Foundation
@testable import SeriesAtlas
import SeriesAtlasNetwork
import Testing

@MainActor
final class PeopleServiceTests {
    private let mockNetworkClient: NetworkClientMock
    private let peopleService: PeopleService

    init() {
        mockNetworkClient = NetworkClientMock()
        peopleService = PeopleService(networkClient: mockNetworkClient)
    }

    @Test
    func testSearchPeopleMapsResponseAndPreservesOrder() async throws {
        mockNetworkClient.dataToReturn = PeopleResponseFixture.complete
        let expectedPeople = try Person.mockPeople()

        let result = try await peopleService.searchPeople(query: "Alex Example & friends")

        #expect(result == expectedPeople)
        #expect(mockNetworkClient.endpoints == ["search/people"])
        #expect(mockNetworkClient.params == ["q": "Alex Example & friends"])
    }

    @Test(arguments: PeopleResponseFixture.optionalFields)
    func testSearchPeopleMapsMissingAndNullOptionalFields(data: Data) async throws {
        mockNetworkClient.dataToReturn = data

        let person = try #require(try await peopleService.searchPeople(query: "Alex Example").first)

        #expect(person.country == nil)
        #expect(person.gender == nil)
        #expect(person.birthday == nil)
        #expect(person.deathday == nil)
        #expect(person.imageURL == nil)
    }

    @Test(arguments: PeopleResponseFixture.fallbackImages)
    func testSearchPeopleUsesOriginalImageAsFallback(data: Data) async throws {
        mockNetworkClient.dataToReturn = data

        let person = try #require(try await peopleService.searchPeople(query: "Alex Example").first)

        #expect(person.imageURL?.absoluteString == "https://example.com/original.jpg")
    }

    @Test
    func testSearchPeopleWithoutResults() async throws {
        mockNetworkClient.dataToReturn = PeopleResponseFixture.empty

        let result = try await peopleService.searchPeople(query: "Unknown person")

        #expect(result.isEmpty)
    }

    @Test(arguments: PeopleResponseFixture.missingRequiredFields + [PeopleResponseFixture.malformedJSON])
    func testSearchPeoplePropagatesDecodingError(data: Data) async {
        mockNetworkClient.dataToReturn = data

        await #expect(throws: DecodingError.self) {
            try await peopleService.searchPeople(query: "Alex Example")
        }
    }

    @Test
    func testSearchPeopleRejectsInvalidRequiredURL() async {
        mockNetworkClient.dataToReturn = PeopleResponseFixture.invalidPersonURL

        await #expect(throws: PersonMappingError.invalidPersonURL) {
            try await peopleService.searchPeople(query: "Alex Example")
        }
    }

    @Test
    func testSearchPeoplePropagatesNetworkError() async {
        mockNetworkClient.errorToThrow = NetworkError.httpStatus(503)

        await #expect(throws: NetworkError.httpStatus(503)) {
            try await peopleService.searchPeople(query: "Alex Example")
        }
    }

    @Test(arguments: [false, true])
    func testSearchPeoplePreservesCancellation(isTransportCancellation: Bool) async {
        mockNetworkClient.errorToThrow = isTransportCancellation ? URLError(.cancelled) : CancellationError()

        await #expect(throws: CancellationError.self) {
            try await peopleService.searchPeople(query: "Alex Example")
        }
    }

    @Test(arguments: [PeopleResponseFixture.empty, PeopleResponseFixture.complete])
    func testSearchPeopleDiscardsResponseAfterCancellation(data: Data) async {
        mockNetworkClient.dataToReturn = data
        let task = Task { try await peopleService.searchPeople(query: "Alex Example") }
        mockNetworkClient.onGet = { task.cancel() }
        defer { mockNetworkClient.onGet = nil }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockNetworkClient.endpoints == ["search/people"])
    }

    @Test(arguments: [" \nAlex  Example\t ", "", " \t\n\r "])
    func testUseCaseSearchesThroughData(query: String) async throws {
        mockNetworkClient.dataToReturn = PeopleResponseFixture.complete
        let repository = PeopleRepository(peopleService: peopleService)
        let useCase = SearchPeopleUseCase(peopleRepository: repository)
        let expectedPeople = try Person.mockPeople()

        let result = try await useCase.execute(query: query)

        #expect(result == expectedPeople)
        #expect(mockNetworkClient.endpoints == ["search/people"])
        #expect(mockNetworkClient.params == ["q": query])
    }
}
