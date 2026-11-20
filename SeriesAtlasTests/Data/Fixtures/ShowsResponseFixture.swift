import Foundation

enum ShowsResponseFixture {
    static let complete = Data(#"""
    [
        {
            "score": 0.9,
            "show": {
                "id": 526,
                "name": "The Office",
                "url": "https://www.tvmaze.com/shows/526/the-office",
                "summary": "<p>The <b>Office</b> &amp; friends.</p><p>Café &#233;pisodes.</p>",
                "genres": ["Comedy"],
                "language": "English",
                "rating": {"average": 8.5},
                "image": {
                    "medium": "https://example.com/office.jpg",
                    "original": "https://example.com/office-original.jpg"
                },
                "status": "Ended"
            }
        },
        {
            "score": 0.7,
            "show": {
                "id": 525,
                "name": "Another Office",
                "url": "https://www.tvmaze.com/shows/525/another-office",
                "summary": null,
                "genres": [],
                "language": null,
                "rating": {"average": null},
                "image": null
            }
        }
    ]
    """#.utf8)

    static let empty = Data("[]".utf8)
    static let malformedJSON = Data("not JSON".utf8)

    static let optionalFields: [Data] = [
        response(),
        response(fields: #", "summary": null, "genres": null, "language": null, "rating": null, "image": null"#),
        response(fields: #", "summary": " \n\t ", "rating": {}, "image": {}"#),
        response(fields: #", "summary": "<p> </p>", "image": {"medium": "relative/image.jpg", "original": "file:///image.jpg"}"#),
    ]

    static let fallbackImages: [Data] = [
        response(fields: #", "image": {"original": "https://example.com/original.jpg"}"#),
        response(fields: #", "image": {"medium": "relative/image.jpg", "original": "https://example.com/original.jpg"}"#),
    ]

    static let missingRequiredFields: [Data] = [
        Data(#"[{"show":{"name":"The Office","url":"https://www.tvmaze.com/shows/526/the-office"}}]"#.utf8),
        Data(#"[{"show":{"id":526,"url":"https://www.tvmaze.com/shows/526/the-office"}}]"#.utf8),
        Data(#"[{"show":{"id":526,"name":"The Office"}}]"#.utf8),
    ]

    static let invalidShowURL = Data(#"[{"show":{"id":526,"name":"The Office","url":"relative/show"}}]"#.utf8)

    private static func response(fields: String = "") -> Data {
        Data("""
        [{"show":{"id":526,"name":"The Office","url":"https://www.tvmaze.com/shows/526/the-office"\(fields)}}]
        """.utf8)
    }
}
