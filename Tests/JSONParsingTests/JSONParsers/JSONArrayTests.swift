@testable import JSONParsing
import Parsing
import XCTest

final class JSONArrayTests: XCTestCase {
  func testSuccessfulParsing() {
    var input: JSONValue = ["a", "b", "c", "d"]

    XCTAssertEqual(
      try JSONArray {
        String.jsonParser()
      }.parse(&input),
      ["a", "b", "c", "d"]
    )
    XCTAssertEqual(input, .empty)
  }

  func testFailedElementParsing() {
    let initialInput: JSONValue = [
      "aaaaa",
      "aaaaa",
      "aabaa",
      "aaaaa",
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONArray {
        JSONString { Rest().filter { $0.allSatisfy { $0 == "a" } } }
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At [index 2]:
        error: processed value "aabaa" failed to satisfy predicate
         --> input:1:1-5
        1 | aabaa
          | ^^^^^ processed input
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testMinimum() throws {
    let initialInput: JSONValue = [1.0, 10.0]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONArray(3...) {
        Int.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected at least 3 elements in array, but found 2."
      )
    }

    XCTAssertEqual(input, initialInput, "Input should remain unchanged")

    XCTAssertThrowsError(
      try JSONArray(3...) {
        Int.jsonParser()
      }.print([1, 2])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An Array parser requiring at least 3 elements was given 2 to print."
      )
    }
  }

  func testMaximum() {
    let initialInput: JSONValue = [1, 10, 100]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONArray(...2) {
        Int.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 0-2 elements in array, but found 3."
      )
    }

    XCTAssertEqual(input, initialInput, "Input should remain unchanged")

    XCTAssertThrowsError(
      try JSONArray(...3) {
        Int.jsonParser()
      }.print([1, 2, 3, 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An Array parser requiring 0-3 elements was given 4 to print."
      )
    }
  }

  func testMinimumAndMaximum() {
    let initialInput: JSONValue = [1, 10, 100]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONArray(5...8) {
        Int.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 5-8 elements in array, but found 3."
      )
    }

    XCTAssertEqual(input, initialInput, "Input should remain unchanged")

    XCTAssertThrowsError(
      try JSONArray(5...8) {
        Int.jsonParser()
      }.print([1, 2, 3, 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An Array parser requiring 5-8 elements was given 4 to print."
      )
    }
  }

  func testExactly() {
    let initialInput: JSONValue = [1, 10, 100]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONArray(2) {
        Int.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 2 elements in array, but found 3."
      )
    }

    XCTAssertEqual(input, initialInput, "Input should remain unchanged")

    XCTAssertThrowsError(
      try JSONArray(...3) {
        Int.jsonParser()
      }.print([1, 2, 3, 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An Array parser requiring 0-3 elements was given 4 to print."
      )
    }
  }

  func testSuccessfulPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(
      try JSONArray {
        String.jsonParser()
      }.print(["1", "2", "3", "4"], into: &input)
    )
    XCTAssertEqual(input, .array(["1", "2", "3", "4"]))
  }

  func testPrintingToNonEmptyJSON() {
    var output = JSONValue.boolean(false)
    XCTAssertThrowsError(try JSONArray { Bool.jsonParser() }.print([], into: &output)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        An Array parser can only print to an empty JSON object but attempted to print to:
        false
        """
      )
    }
  }
}
