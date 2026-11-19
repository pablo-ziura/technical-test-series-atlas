import Foundation

struct Show: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let summary: String?
    let genres: [String]
    let language: String?
    let rating: Double?
    let imageURL: URL?
    let tvmazeURL: URL
}
