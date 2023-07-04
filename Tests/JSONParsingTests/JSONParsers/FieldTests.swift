@testable import JSONParsing
import Parsing
import XCTest

final class FieldTests: XCTestCase {
  func testSuccessfulParsingSingleField() {
    var input: JSONValue = [
      "first_name": "Steve",
      "age": 50.0,
    ]

    XCTAssertEqual(
      try Field("first_name") {
        String.jsonParser()
      }.parse(&input),
      "Steve"
    )
    XCTAssertEqual(
      input,
      [
        "age": 50.0,
      ]
    )
  }

  func testParsingWithNestedFieldParsers() {
    var input: JSONValue = [
      "first_name": "Steve",
      "contact_info": [
        "email": "steve@apple.com",
        "phone_number": "00000",
      ],
    ]

    XCTAssertEqual(
      try Field("contact_info") {
        Field("email") {
          String.jsonParser()
        }
      }.parse(&input),
      "steve@apple.com"
    )
    XCTAssertEqual(
      input,
      [
        "first_name": "Steve",
        "contact_info": [
          "phone_number": "00000",
        ],
      ]
    )
  }

  func testParsingFromWrongType() {
    let initialInput: JSONValue = 5
    var input = initialInput

    XCTAssertThrowsError(
      try Field("last_name") {
        String.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        Expected an object (containing the key "last_name"), but found:
        5
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testParsingWithMissingKey() {
    let initialInput: JSONValue = [
      "first_name": "Steve",
      "age": 50.0,
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try Field("last_name") {
        String.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        "Key \"last_name\" not present."
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testFailedParsingAtKey() {
    let initialInput: JSONValue = [
      "first_name": "Steve",
      "age": 50.0,
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try Field("age") {
        String.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "age":
        Expected a string, but found:
        50.0
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testParsingWithNullValue() {
    let input: JSONValue = ["key": .null]

    XCTAssertNoThrow(try Field("key") { Null() }.parse(input), "explicitly parsing null should be ok")
    XCTAssertNoThrow(try Field("key", allowNull: true).parse(input))
    XCTAssertThrowsError(
      try Field("key").parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key":
        error: unexpected input
        """
      )
    }
    XCTAssertThrowsError(
      try Field("key") { Int.jsonParser() }.parse(input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "key":
        Expected an integer number, but found:
        null
        """
      )
    }
  }

  func testPrintingIntoEmptyObject() {
    var input = JSONValue.empty

    XCTAssertNoThrow(
      try Field("first_name") {
        String.jsonParser()
      }.print("Steve", into: &input)
    )
    XCTAssertEqual(input, ["first_name": "Steve"])
  }

  func testPrintingIntoNonEmptyObject() {
    var input: JSONValue = [
      "first_name": "Steve",
    ]

    XCTAssertNoThrow(
      try Field("age") {
        Int.jsonParser()
      }.print(50, into: &input)
    )
    XCTAssertEqual(
      input,
      [
        "age": 50,
        "first_name": "Steve",
      ]
    )
  }

  func testPrintingIntoNonObjectFailure() {
    var input: JSONValue = 10

    XCTAssertThrowsError(
      try Field("key") {
        Int.jsonParser()
      }.print(5, into: &input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        A Field parser can only print to an object but attempted to print to:
        10
        """
      )
    }
    XCTAssertEqual(input, 10, "input should remain unchanged")
  }
}
