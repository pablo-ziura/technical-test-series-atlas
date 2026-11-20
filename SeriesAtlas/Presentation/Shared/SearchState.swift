import Foundation

enum SearchState<Item: Sendable>: Sendable {
    case idle
    case loading
    case results([Item])
    case empty
    case failure(String)
}

extension SearchState: Equatable where Item: Equatable {}
