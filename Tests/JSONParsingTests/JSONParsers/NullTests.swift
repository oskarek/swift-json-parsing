@testable import JSONParsing
import XCTest

final class NullTests: XCTestCase {
  func testSuccessfulParsing() {
    var input = JSONValue.null
    XCTAssertNoThrow(try Null().parse(&input))
    XCTAssertEqual(input, .empty)
  }

  func testParseFailure() {
    let initialInput: JSONValue = "hello"
    var input = initialInput

    XCTAssertThrowsError(try Null().parse(&input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected a null value, but found:
        "hello"
        """
      )
    }

    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testSuccessfulPrinting() {
    var input = JSONValue.empty
    XCTAssertNoThrow(try Null().print((), into: &input))
    XCTAssertEqual(input, .null)
  }

  func testPrintingToNonEmptyJSON() {
    var input: JSONValue = false
    XCTAssertThrowsError(try Null().print((), into: &input)) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A Null parser can only print to an empty JSON object but attempted to print to:
        false
        """
      )
    }
    XCTAssertEqual(input, false, "input should remain unchanged")
  }
}
