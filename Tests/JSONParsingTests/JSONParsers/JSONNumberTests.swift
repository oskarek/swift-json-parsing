@testable import JSONParsing
import XCTest

final class JSONNumberTests: XCTestCase {
  func testBasicIntegerParse() {
    var input: JSONValue = 5

    XCTAssertEqual(try JSONNumber<Int>().parse(&input), 5)
    XCTAssertEqual(input, .empty)
  }

  func testBasicFloatingPointParse() {
    var input: JSONValue = 12.0

    XCTAssertEqual(try JSONNumber<Double>().parse(&input), 12.0)
    XCTAssertEqual(input, .empty)
  }

  func testBasicFloatingPointFromIntegerParse() {
    var input: JSONValue = -10

    XCTAssertEqual(try JSONNumber<Double>().parse(&input), -10.0)
    XCTAssertEqual(input, .empty)
  }

  func testForcedFloatingPointParsingFailure() {
    var input: JSONValue = 55

    XCTAssertThrowsError(try JSONNumber<Double>(allowInteger: false).parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a floating point number, but found:
        55
        """
      )
    }
    XCTAssertEqual(input, 55, "input should remain unchanged")
  }

  func testIntegerParsingFailure() {
    let initialInput: JSONValue = 55.0
    var input = initialInput

    XCTAssertThrowsError(try JSONNumber<Int>().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected an integer number, but found:
        55.0
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testWrongTypeParsingFailure() {
    let initialInput: JSONValue = "hello"
    var input = initialInput

    XCTAssertThrowsError(try JSONNumber<Int>().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected an integer number, but found:
        "hello"
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")

    XCTAssertThrowsError(try JSONNumber<Double>().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a number, but found:
        "hello"
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")

    XCTAssertThrowsError(try JSONNumber<Double>(allowInteger: false).parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a floating point number, but found:
        "hello"
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testIntegerPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try JSONNumber<Int>().print(14, into: &input))
    XCTAssertEqual(input, 14)
  }

  func testFloatingPointPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try JSONNumber<Double>().print(1.0, into: &input))
    XCTAssertEqual(input, 1.0)
  }

  func testPrintingToNonEmptyJSON() {
    var input: JSONValue = "hello"
    XCTAssertThrowsError(try JSONNumber<Int>().print(0, into: &input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A JSONNumber parser can only print to an empty JSON object but attempted to print to:
        "hello"
        """
      )
    }
    XCTAssertEqual(input, "hello", "input should remain unchanged")
  }
}
