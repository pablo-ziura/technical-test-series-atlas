import Foundation

struct ShowMapper {
    static func map(_ dto: ShowDTO) async throws -> Show {
        guard let tvmazeURL = webURL(from: dto.url) else {
            throw ShowMappingError.invalidShowURL
        }

        let summary = await HTMLSummaryConverter.plainText(from: dto.summary)

        return Show(
            id: dto.id,
            name: dto.name,
            summary: summary,
            genres: dto.genres ?? [],
            language: dto.language,
            rating: dto.rating?.average,
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
