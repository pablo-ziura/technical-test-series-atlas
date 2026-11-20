import Foundation

protocol SearchPeopleUseCaseProtocol: Sendable {
    func execute(query: String) async throws -> [Person]
}
