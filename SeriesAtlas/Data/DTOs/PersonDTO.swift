import Foundation

struct PersonDTO: Codable, Sendable {
    let id: Int
    let name: String
    let url: String
    let country: PersonCountryDTO?
    let gender: String?
    let birthday: String?
    let deathday: String?
    let image: PersonImageDTO?
}

struct PersonCountryDTO: Codable, Sendable {
    let name: String?
}

struct PersonImageDTO: Codable, Sendable {
    let medium: String?
    let original: String?
}
