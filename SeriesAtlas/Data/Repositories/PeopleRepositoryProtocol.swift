import Foundation

protocol PeopleRepositoryProtocol: Sendable {
    func searchPeople(query: String) async throws -> [Person]
}
