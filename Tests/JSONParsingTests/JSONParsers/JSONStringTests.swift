@testable import JSONParsing
import Parsing
import XCTest

final class JSONStringTests: XCTestCase {
  func testBasicParse() {
    var input: JSONValue = "This is a string."

    XCTAssertEqual(try JSONString().parse(&input), "This is a string.")
    XCTAssertEqual(input, .empty)
  }

  func testEmptyStringParse() {
    var input: JSONValue = ""

    XCTAssertEqual(try JSONString().parse(&input), "")
    XCTAssertEqual(input, .empty)
  }

  func testParserWithStringParser() {
    var input: JSONValue = "hello,world"

    XCTAssertEqual(
      try JSONString {
        Parse(+) {
          Prefix { $0 != "," }.map(.string)
          ","
          Rest().map(.string)
        }
      }.parse(&input),
      "helloworld"
    )
    XCTAssertEqual(input, .empty)
  }

  func testParseFailureWrongType() {
    var input: JSONValue = 10.8

    XCTAssertThrowsError(try JSONString().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a string, but found:
        10.8
        """
      )
    }
    XCTAssertEqual(input, 10.8, "input should remain unchanged")
  }

  func testParseFailureFailedStringParsing() {
    var input: JSONValue = "hello world"

    XCTAssertThrowsError(
      try JSONString {
        Parse(+) {
          Prefix { $0 != "," }
          ","
          Rest()
        }
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        error: unexpected input
         --> input:1:12
        1 | hello world
          |            ^ expected ","
        """
      )
    }
    XCTAssertEqual(input, "hello world", "input should remain unchanged")
  }

  func testParseFailurePartialStringParsing() {
    var input: JSONValue = "12345a"

    XCTAssertThrowsError(
      try JSONString {
        Prefix { $0.isNumber }
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        error: unexpected input
         --> input:1:6
        1 | 12345a
          |      ^ expected end of input
        """
      )
    }
    XCTAssertEqual(input, "12345a", "input should remain unchanged")
  }

  func testSuccessfulPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try JSONString().print("hello", into: &input))
    XCTAssertEqual(input, "hello")
  }

  func testEmptyStringPrinting() {
    var input = JSONValue.empty

    XCTAssertNoThrow(try JSONString().print("", into: &input))
    XCTAssertEqual(input, "")
  }

  func testPrintingToNonEmptyJSON() {
    var input = JSONValue.null
    XCTAssertThrowsError(try JSONString().print("hello", into: &input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A String parser can only print to an empty JSON object but attempted to print to:
        null
        """
      )
    }
  }
}
