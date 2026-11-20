import Foundation
@testable import SeriesAtlas
import Testing

extension Person {
    static func mockPeople() throws -> [Person] {
        let imageURL: URL = try #require(URL(string: "https://example.com/alex.jpg"))
        return [
            Person(
                id: 101,
                name: "Alex Example",
                country: "Canada",
                gender: "Female",
                birthday: "1982-11-03",
                deathday: "2020-02-29",
                imageURL: imageURL,
                tvmazeURL: try #require(URL(string: "https://www.tvmaze.com/people/101/alex-example"))
            ),
            Person(
                id: 100,
                name: "Sam Example",
                country: nil,
                gender: nil,
                birthday: nil,
                deathday: nil,
                imageURL: nil,
                tvmazeURL: try #require(URL(string: "https://www.tvmaze.com/people/100/sam-example"))
            ),
        ]
    }
}
