import Foundation

struct PersonMapper {
    static func map(_ dto: PersonDTO) throws -> Person {
        guard let tvmazeURL = webURL(from: dto.url) else {
            throw PersonMappingError.invalidPersonURL
        }

        return Person(
            id: dto.id,
            name: dto.name,
            country: dto.country?.name,
            gender: dto.gender,
            birthday: dto.birthday,
            deathday: dto.deathday,
            imageURL: webURL(from: dto.image?.medium) ?? webURL(from: dto.image?.original),
            tvmazeURL: tvmazeURL
        )
    }

    private static func webURL(from value: String?) -> URL? {
        guard let value, let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
}
