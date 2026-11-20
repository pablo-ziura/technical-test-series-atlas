import Foundation

protocol PeopleServiceProtocol: Sendable {
    func searchPeople(query: String) async throws -> [Person]
}
