import Foundation

struct Person: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let country: String?
    let gender: String?
    let birthday: String?
    let deathday: String?
    let imageURL: URL?
    let tvmazeURL: URL
}
