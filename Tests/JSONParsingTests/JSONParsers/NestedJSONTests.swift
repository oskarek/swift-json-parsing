@testable import JSONParsing
import Parsing
import XCTest

final class NestedJSONTests: XCTestCase {
  func testNestedJSONParsing() {
    let input: JSONValue = [
      "key1": "value1",
      "key2": [
        [
          "nested_key": false,
        ],
        [
          "nested_key": "hello",
        ],
      ],
    ]

    XCTAssertThrowsError(
      try Field("key2") {
        JSONArray {
          Field("nested_key") {
            Bool.jsonParser()
          }
        }
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key2"/[index 1]/"nested_key":
        Expected a boolean, but found:
        "hello"
        """
      )
    }
  }

  func testNestedJSONParsingWithOneOf() {
    let input: JSONValue = [
      "key1": "value1",
      "key2": [
        [
          "nested_key": false,
        ],
        [
          "nested_key": "test",
        ],
      ],
    ]

    XCTAssertThrowsError(
      try Field("key2") {
        JSONArray {
          OneOf {
            Field("nested_key") {
              Bool.jsonParser()
            }
            Field("nested_key") {
              JSONString {
                OneOf {
                  "0".map { false }
                  "1".map { true }
                }
              }
            }
          }
        }
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key2"/[index 1]:
        error: multiple failures occurred

        At "nested_key":
        Expected a boolean, but found:
        "test"

        At "nested_key":
        error: unexpected input
         --> input:1:1
        1 | test
          | ^ expected "0"
          | ^ expected "1"
        """
      )
    }
  }

  func testNestedJSONParsingWithStringParser() {
    let input: JSONValue = [
      "key1": "value1",
      "key2": [
        [
          "nested_key": "aaaaaaa",
        ],
        [
          "nested_key": "aaaabaa",
        ],
      ],
    ]

    XCTAssertThrowsError(
      try Field("key2") {
        JSONArray {
          Field("nested_key") {
            JSONString { Rest().filter { $0.allSatisfy { $0 == "a" } } }
          }
        }
      }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key2"/[index 1]/"nested_key":
        error: processed value "aaaabaa" failed to satisfy predicate
         --> input:1:1-7
        1 | aaaabaa
          | ^^^^^^^ processed input
        """
      )
    }
  }

  func testNestedJSONPrinting() {
    XCTAssertThrowsError(
      try Field("key2") {
        JSONArray {
          Field("nested_key") {
            JSONArray(2...) { Bool.jsonParser() }
          }
        }
      }.print([[false, true], [true]])
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key2"/[index 1]/"nested_key":
        An Array parser requiring at least 2 elements was given 1 to print.
        """
      )
    }
  }
}
