import Foundation
@testable import SeriesAtlas
import Testing

extension Show {
    static func mockShows() throws -> [Show] {
        let imageURL: URL = try #require(URL(string: "https://example.com/office.jpg"))
        return [
            Show(
                id: 526,
                name: "The Office",
                summary: "The everyday lives of office employees.",
                genres: ["Comedy"],
                language: "English",
                rating: 8.5,
                imageURL: imageURL,
                tvmazeURL: try #require(URL(string: "https://www.tvmaze.com/shows/526/the-office"))
            ),
            Show(
                id: 525,
                name: "Another Office",
                summary: nil,
                genres: [],
                language: nil,
                rating: nil,
                imageURL: nil,
                tvmazeURL: try #require(URL(string: "https://www.tvmaze.com/shows/525/another-office"))
            ),
        ]
    }
}
