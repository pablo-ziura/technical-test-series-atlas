enum UITestResponses {
    static let shows = #"""
    [
        {
            "show": {
                "id": 101,
                "name": "Atlas Harbor",
                "url": "https://www.tvmaze.com/shows/101/atlas-harbor",
                "summary": "<p>Stories from a coastal town.</p>",
                "genres": ["Comedy"],
                "language": "Spanish",
                "rating": {"average": 7.2},
                "image": null
            }
        },
        {
            "show": {
                "id": 102,
                "name": "Atlas Beyond",
                "url": "https://www.tvmaze.com/shows/102/atlas-beyond",
                "summary": "<p>A crew explores <b>distant worlds</b> &amp; finds a new home.</p>",
                "genres": ["Drama", "Adventure"],
                "language": "English",
                "rating": {"average": 8.5},
                "image": null
            }
        }
    ]
    """#

    static let otherShows = #"""
    [
        {
            "show": {
                "id": 103,
                "name": "Orbit Station",
                "url": "https://www.tvmaze.com/shows/103/orbit-station",
                "summary": "<p>Life aboard a space station.</p>",
                "genres": ["Science-Fiction"],
                "language": "English",
                "rating": {"average": 9.0},
                "image": null
            }
        }
    ]
    """#

    static let people = #"""
    [
        {
            "person": {
                "id": 201,
                "name": "Alex Morgan",
                "url": "https://www.tvmaze.com/people/201/alex-morgan",
                "country": {"name": "United Kingdom"},
                "gender": "Female",
                "birthday": "1990-06-21",
                "image": null
            }
        },
        {
            "person": {
                "id": 202,
                "name": "Alex Rivera",
                "url": "https://www.tvmaze.com/people/202/alex-rivera",
                "country": {"name": "Canada"},
                "gender": "Male",
                "birthday": "1988-04-12",
                "image": null
            }
        }
    ]
    """#
}
