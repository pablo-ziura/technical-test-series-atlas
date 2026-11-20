import Foundation

enum PeopleResponseFixture {
    static let complete = Data(#"""
    [
        {
            "score": 0.9,
            "person": {
                "id": 101,
                "name": "Alex Example",
                "url": "https://www.tvmaze.com/people/101/alex-example",
                "country": {"name": "Canada", "code": "CA", "timezone": "America/Toronto"},
                "gender": "Female",
                "birthday": "1982-11-03",
                "deathday": "2020-02-29",
                "image": {
                    "medium": "https://example.com/alex.jpg",
                    "original": "https://example.com/alex-original.jpg"
                },
                "updated": 1639310734,
                "_links": {"self": {"href": "https://api.tvmaze.com/people/101"}}
            }
        },
        {
            "score": 0.7,
            "person": {
                "id": 100,
                "name": "Sam Example",
                "url": "https://www.tvmaze.com/people/100/sam-example",
                "country": null,
                "gender": null,
                "birthday": null,
                "deathday": null,
                "image": null
            }
        }
    ]
    """#.utf8)

    static let empty = Data("[]".utf8)
    static let malformedJSON = Data("not JSON".utf8)

    static let optionalFields: [Data] = [
        response(),
        response(fields: #", "country": null, "gender": null, "birthday": null, "deathday": null, "image": null"#),
        response(fields: #", "country": {}, "image": {}"#),
        response(fields: #", "image": {"medium": "relative/image.jpg", "original": "file:///image.jpg"}"#),
    ]

    static let fallbackImages: [Data] = [
        response(fields: #", "image": {"original": "https://example.com/original.jpg"}"#),
        response(fields: #", "image": {"medium": "relative/image.jpg", "original": "https://example.com/original.jpg"}"#),
    ]

    static let missingRequiredFields: [Data] = [
        Data(#"[{"person":{"name":"Alex Example","url":"https://www.tvmaze.com/people/101/alex-example"}}]"#.utf8),
        Data(#"[{"person":{"id":101,"url":"https://www.tvmaze.com/people/101/alex-example"}}]"#.utf8),
        Data(#"[{"person":{"id":101,"name":"Alex Example"}}]"#.utf8),
    ]

    static let invalidPersonURL = Data(#"[{"person":{"id":101,"name":"Alex Example","url":"relative/person"}}]"#.utf8)

    private static func response(fields: String = "") -> Data {
        Data("""
        [{"person":{"id":101,"name":"Alex Example","url":"https://www.tvmaze.com/people/101/alex-example"\(fields)}}]
        """.utf8)
    }
}
