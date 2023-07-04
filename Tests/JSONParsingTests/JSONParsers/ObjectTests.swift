@testable import JSONParsing
import Parsing
import XCTest

final class ObjectTests: XCTestCase {
  func testSuccessfulParsing() {
    var input: JSONValue = [
      "key1": "a",
      "key2": "b",
      "key3": "c",
      "key4": "d",
    ]

    XCTAssertEqual(
      try JSONObject {
        String.jsonParser()
      }.parse(&input),
      [
        "key1": "a",
        "key2": "b",
        "key3": "c",
        "key4": "d",
      ]
    )
    XCTAssertEqual(input, .empty)
  }

  func testFailedValueParsing() {
    let initialInput: JSONValue = [
      "key1": "aaaaa",
      "key2": "aaaaa",
      "key3": "aabaa",
      "key4": "aaaab",
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONObject {
        JSONString { Rest().filter { $0.allSatisfy { $0 == "a" } } }
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key3":
        error: processed value "aabaa" failed to satisfy predicate
         --> input:1:1-5
        1 | aabaa
          | ^^^^^ processed input
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testParsingWithKeyParser() {
    var input: JSONValue = [
      "key_1": "a",
      "key_2": "b",
      "key_3": "c",
      "key_4": "d",
    ]

    XCTAssertEqual(
      try JSONObject {
        String.jsonParser()
      } keys: {
        "key_"
        Int.parser()
      }.parse(&input),
      [1: "a", 2: "b", 3: "c", 4: "d"]
    )
    XCTAssertEqual(input, .empty)
  }

  func testPrintingWithKeyParser() {
    var input = JSONValue.empty

    XCTAssertNoThrow(
      try JSONObject {
        String.jsonParser()
      } keys: {
        "key_"
        Int.parser()
      }
      .print([1: "a", 2: "b", 3: "c", 4: "d"], into: &input)
    )
    XCTAssertEqual(
      input,
      [
        "key_1": "a",
        "key_2": "b",
        "key_3": "c",
        "key_4": "d",
      ]
    )
  }

  func testParsingAndPrintingWithKeyConversion() {
    struct UserID: RawRepresentable, Hashable {
      var rawValue: String
    }
    let initialInput: JSONValue = .object([
      "abc": "user 1",
      "def": "user 2",
    ])
    var input = initialInput

    let parser = JSONObject(keys: .representing(UserID.self)) {
      String.jsonParser()
    }
    let expectedOutput = [
      UserID(rawValue: "abc"): "user 1",
      UserID(rawValue: "def"): "user 2",
    ]
    XCTAssertEqual(
      try parser.parse(&input),
      expectedOutput
    )
    XCTAssertEqual(input, .empty)

    XCTAssertEqual(try parser.print(expectedOutput), initialInput)
  }

  func testMinimum() throws {
    let initialInput: JSONValue = [
      "key1": 1.0,
      "key2": 10.0,
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try JSONObject(3...) {
        Int.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected at least 3 key/value pairs in object, but found 2."
      )
    }

    XCTAssertEqual(input, initialInput, "Input should remain unchanged")

    XCTAssertThrowsError(
      try JSONObject(3...) {
        Int.jsonParser()
      }.print(["key1": 1, "key2": 2])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An JSONObject parser requiring at least 3 key/value pairs was given 2 to print."
      )
    }
  }

  func testMaximum() {
    let input: JSONValue = [
      "key1": 1,
      "key2": 10,
      "key3": 100,
    ]

    XCTAssertThrowsError(
      try JSONObject(...2) {
        Int.jsonParser()
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 0-2 key/value pairs in object, but found 3."
      )
    }

    XCTAssertThrowsError(
      try JSONObject(...3) {
        Int.jsonParser()
      }.print(["a": 1, "b": 2, "c": 3, "d": 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An JSONObject parser requiring 0-3 key/value pairs was given 4 to print."
      )
    }
  }

  func testMinimumAndMaximum() {
    let input: JSONValue = [
      "key1": 1,
      "key2": 10,
      "key3": 100,
    ]

    XCTAssertThrowsError(
      try JSONObject(4 ... 6) {
        Int.jsonParser()
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 4-6 key/value pairs in object, but found 3."
      )
    }

    XCTAssertThrowsError(
      try JSONObject(1...3) {
        Int.jsonParser()
      }.print(["a": 1, "b": 2, "c": 3, "d": 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An JSONObject parser requiring 1-3 key/value pairs was given 4 to print."
      )
    }
  }

  func testExactly() {
    let input: JSONValue = [
      "key1": 1,
      "key2": 10,
      "key3": 100,
    ]

    XCTAssertThrowsError(
      try JSONObject(2) {
        Int.jsonParser()
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Expected 2 key/value pairs in object, but found 3."
      )
    }

    XCTAssertThrowsError(
      try JSONObject(5) {
        Int.jsonParser()
      }.print(["a": 1, "b": 2, "c": 3, "d": 4])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "An JSONObject parser requiring 5 key/value pairs was given 4 to print."
      )
    }
  }

  func testSuccessfulPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(
      try JSONObject {
        String.jsonParser()
      }.print(["a": "1", "b": "2", "c": "3", "d": "4"], into: &input)
    )
    XCTAssertEqual(input, .object(["a": .string("1"), "b": .string("2"), "c": .string("3"), "d": .string("4")]))
  }

  func testPrintingToNonEmptyJSON() {
    var input: JSONValue = false
    XCTAssertThrowsError(try JSONObject { Bool.jsonParser() }.print([:], into: &input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A JSONObject parser can only print to an empty JSON object but attempted to print to:
        false
        """
      )
    }
  }
}
