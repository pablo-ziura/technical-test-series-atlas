import XCTest

final class SeriesAtlasUITests: XCTestCase {
    private enum Timeout {
        static let interaction: TimeInterval = 5
        // WebKit puede tardar en arrancar en un simulador frío de CI; la espera termina al llegar el resultado.
        static let search: TimeInterval = 30
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testShowsSearchOpensSelectedDetailAndPreservesResultsOnReturn() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Shows"].exists)
        XCTAssertTrue(app.staticTexts["Enter a name and tap Search."].exists)

        search("Atlas", in: app)
        XCTAssertTrue(result("shows.result.101", in: app).waitForExistence(timeout: Timeout.search))
        let selectedResult = result("shows.result.102", in: app)
        XCTAssertTrue(selectedResult.waitForExistence(timeout: Timeout.interaction))
        selectedResult.tap()

        let detail = app.descendants(matching: .any)["show.detail"].firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: Timeout.interaction))
        XCTAssertTrue(app.navigationBars["Atlas Beyond"].exists)
        assertDetailValue("Drama, Adventure", labeled: "Genres", in: detail)
        assertDetailValue("English", labeled: "Language", in: detail)
        assertDetailValue("8.5", labeled: "Rating", in: detail)
        assertVisible(
            detail.staticTexts["A crew explores distant worlds & finds a new home."],
            scrolling: detail
        )

        goBack(from: "Atlas Beyond", in: app)
        XCTAssertTrue(queryField(in: app).waitForExistence(timeout: Timeout.interaction))
        XCTAssertEqual(queryField(in: app).value as? String, "Atlas")
        XCTAssertTrue(result("shows.result.101", in: app).exists)
        XCTAssertTrue(result("shows.result.102", in: app).exists)
    }

    @MainActor
    func testPeopleKeyboardSearchOpensSelectedDetailAndPreservesResultsOnReturn() {
        let app = launchApp()
        app.tabBars.buttons["People"].tap()
        let field = queryField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: Timeout.interaction))
        field.tap()
        field.typeText("Alex\n")

        XCTAssertTrue(result("people.result.201", in: app).waitForExistence(timeout: Timeout.search))
        let selectedResult = result("people.result.202", in: app)
        XCTAssertTrue(selectedResult.waitForExistence(timeout: Timeout.interaction))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        selectedResult.tap()

        let detail = app.descendants(matching: .any)["person.detail"].firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: Timeout.interaction))
        XCTAssertTrue(app.navigationBars["Alex Rivera"].exists)
        assertDetailValue("Canada", labeled: "Country", in: detail)
        assertDetailValue("Male", labeled: "Gender", in: detail)
        assertDetailValue("1988-04-12", labeled: "Birthday", in: detail)

        goBack(from: "Alex Rivera", in: app)
        XCTAssertTrue(queryField(in: app).waitForExistence(timeout: Timeout.interaction))
        XCTAssertEqual(queryField(in: app).value as? String, "Alex")
        XCTAssertTrue(result("people.result.201", in: app).exists)
        XCTAssertTrue(result("people.result.202", in: app).exists)
    }

    @MainActor
    func testRetryRecoversOriginalQueryAfterEditingSearchField() {
        let app = launchApp(scenario: "retry")
        search("Atlas", in: app)

        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: Timeout.search))
        XCTAssertTrue(app.staticTexts["Search unavailable"].exists)
        XCTAssertTrue(app.staticTexts["Unable to search shows. Please try again."].exists)

        replaceQuery(with: "Edited", in: app)
        XCTAssertTrue(retry.exists)
        app.scrollViews.containing(.button, identifier: "Retry").firstMatch.swipeDown()
        let retryIsHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND isHittable == true"),
            object: retry
        )
        wait(for: [retryIsHittable], timeout: Timeout.interaction)
        retry.tap()

        XCTAssertTrue(result("shows.result.102", in: app).waitForExistence(timeout: Timeout.search))
        XCTAssertTrue(result("shows.result.101", in: app).exists)
        XCTAssertFalse(result("shows.result.103", in: app).exists)
        XCTAssertEqual(queryField(in: app).value as? String, "Edited")
        XCTAssertFalse(retry.exists)
        XCTAssertFalse(app.staticTexts["Search unavailable"].exists)
    }

    @MainActor
    func testTabsPreserveIndependentDetailsQueriesAndResults() {
        let app = launchApp()
        search("Atlas", in: app)
        let show = result("shows.result.102", in: app)
        XCTAssertTrue(show.waitForExistence(timeout: Timeout.search))
        show.tap()
        XCTAssertTrue(app.navigationBars["Atlas Beyond"].waitForExistence(timeout: Timeout.interaction))

        app.tabBars.buttons["People"].tap()
        search("Alex", in: app)
        let person = result("people.result.202", in: app)
        XCTAssertTrue(person.waitForExistence(timeout: Timeout.search))
        person.tap()
        XCTAssertTrue(app.navigationBars["Alex Rivera"].waitForExistence(timeout: Timeout.interaction))

        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(app.navigationBars["Atlas Beyond"].waitForExistence(timeout: Timeout.interaction))
        XCTAssertTrue(app.descendants(matching: .any)["show.detail"].firstMatch.exists)

        app.tabBars.buttons["People"].tap()
        XCTAssertTrue(app.navigationBars["Alex Rivera"].waitForExistence(timeout: Timeout.interaction))
        XCTAssertTrue(app.descendants(matching: .any)["person.detail"].firstMatch.exists)
        goBack(from: "Alex Rivera", in: app)
        XCTAssertTrue(queryField(in: app).waitForExistence(timeout: Timeout.interaction))
        XCTAssertEqual(queryField(in: app).value as? String, "Alex")
        XCTAssertTrue(result("people.result.201", in: app).exists)
        XCTAssertTrue(result("people.result.202", in: app).exists)
        XCTAssertFalse(result("shows.result.102", in: app).exists)

        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(app.navigationBars["Atlas Beyond"].waitForExistence(timeout: Timeout.interaction))
        goBack(from: "Atlas Beyond", in: app)
        XCTAssertTrue(queryField(in: app).waitForExistence(timeout: Timeout.interaction))
        XCTAssertEqual(queryField(in: app).value as? String, "Atlas")
        XCTAssertTrue(result("shows.result.101", in: app).exists)
        XCTAssertTrue(result("shows.result.102", in: app).exists)
        XCTAssertFalse(result("people.result.202", in: app).exists)
    }

    @MainActor
    func testEmptyResultsReplacePreviousListAndAllowAnotherSearch() {
        let app = launchApp()
        search("Atlas", in: app)
        XCTAssertTrue(result("shows.result.102", in: app).waitForExistence(timeout: Timeout.search))

        search("Missing", in: app)
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: Timeout.search))
        XCTAssertTrue(app.staticTexts["No results found for “Missing”. Try a different name."].exists)
        XCTAssertFalse(result("shows.result.101", in: app).exists)
        XCTAssertFalse(result("shows.result.102", in: app).exists)

        search("Orbit", in: app)
        XCTAssertTrue(result("shows.result.103", in: app).waitForExistence(timeout: Timeout.search))
        XCTAssertEqual(queryField(in: app).value as? String, "Orbit")
        XCTAssertFalse(app.staticTexts["No results"].exists)
        XCTAssertFalse(result("shows.result.102", in: app).exists)
    }

    @MainActor
    private func launchApp(scenario: String = "standard") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SERIES_ATLAS_UI_TEST_SCENARIO"] = scenario
        app.launch()
        XCTAssertTrue(queryField(in: app).waitForExistence(timeout: Timeout.interaction))
        return app
    }

    @MainActor
    private func queryField(in app: XCUIApplication) -> XCUIElement {
        app.textFields["search.query"]
    }

    @MainActor
    private func result(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    private func replaceQuery(with query: String, in app: XCUIApplication) {
        let field = queryField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: Timeout.interaction))
        field.tap()
        let currentText = field.value as? String ?? ""
        if currentText != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count))
        }
        field.typeText(query)
        let queryIsUpdated = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", query),
            object: field
        )
        wait(for: [queryIsUpdated], timeout: Timeout.interaction)
    }

    @MainActor
    private func search(_ query: String, in app: XCUIApplication) {
        replaceQuery(with: query, in: app)
        app.buttons["search.submit"].tap()
    }

    @MainActor
    private func goBack(from title: String, in app: XCUIApplication) {
        app.navigationBars[title].buttons.element(boundBy: 0).tap()
    }

    @MainActor
    private func assertDetailValue(
        _ value: String,
        labeled label: String,
        in detail: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = detail.staticTexts["\(label), \(value)"]
        assertVisible(field, scrolling: detail, file: file, line: line)
    }

    @MainActor
    private func assertVisible(
        _ element: XCUIElement,
        scrolling container: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<5 {
            if element.exists && element.isHittable {
                return
            }
            container.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "Expected visible detail content: \(element)\n\(container.debugDescription)", file: file, line: line)
    }
}
