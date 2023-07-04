@testable import JSONParsing
import XCTest

final class JSONBooleanTests: XCTestCase {
  func testParseTrue() {
    var input: JSONValue = true
    XCTAssertEqual(
      try JSONBoolean().parse(&input),
      true
    )
    XCTAssertEqual(input, .empty)
  }

  func testParseFalse() {
    var input: JSONValue = false
    XCTAssertEqual(
      try JSONBoolean().parse(&input),
      false
    )
    XCTAssertEqual(input, .empty)
  }

  func testParseFailure() {
    var input: JSONValue = 4.5
    XCTAssertThrowsError(try JSONBoolean().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a boolean, but found:
        4.5
        """
      )
    }
    XCTAssertEqual(input, 4.5, "input should remain unchanged")
  }

  func testParseFailureWithObject() {
    let initialInput: JSONValue = [
      "key1": 4.0,
      "key2": ["nested_key": false],
      "key3": "hello",
      "key4": .null,
    ]
    var input = initialInput
    XCTAssertThrowsError(try JSONBoolean().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a boolean, but found:
        {
          "key1": 4.0,
          "key2": { "nested_key": false },
          "key3": "hello",
          ...(+1 more)
        }
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testTruePrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try JSONBoolean().print(true, into: &input))
    XCTAssertEqual(input, .boolean(true))
  }

  func testFalsePrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try JSONBoolean().print(false, into: &input))
    XCTAssertEqual(input, .boolean(false))
  }

  func testPrintingToNonEmptyJSON() {
    var input: JSONValue = "hello"
    XCTAssertThrowsError(try JSONBoolean().print(false, into: &input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A JSONBoolean parser can only print to an empty JSON object but attempted to print to:
        "hello"
        """
      )
    }
    XCTAssertEqual(input, .string("hello"))
  }
}
