import Foundation

struct ShowDTO: Codable, Sendable {
    let id: Int
    let name: String
    let url: String
    let summary: String?
    let genres: [String]?
    let language: String?
    let rating: RatingDTO?
    let image: ShowImageDTO?
}

struct RatingDTO: Codable, Sendable {
    let average: Double?
}

struct ShowImageDTO: Codable, Sendable {
    let medium: String?
    let original: String?
}
