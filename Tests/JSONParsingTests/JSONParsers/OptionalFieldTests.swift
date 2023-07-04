@testable import JSONParsing
import Parsing
import XCTest

final class OptionalFieldTests: XCTestCase {
  func testSuccessfulParsingSingleField() {
    var input: JSONValue = [
      "first_name": "Steve",
      "age": 50.0,
    ]

    XCTAssertEqual(
      try OptionalField("first_name") {
        String.jsonParser()
      }.parse(&input),
      "Steve" as String?
    )
    XCTAssertEqual(
      input,
      [
        "age": 50.0,
      ]
    )
  }

  func testParsingWithMissingKeyAndNoDefault() {
    let initialInput: JSONValue = [
      "first_name": "Steve",
      "age": 50,
    ]
    var input = initialInput

    XCTAssertEqual(
      try OptionalField("last_name") {
        String.jsonParser()
      }.parse(&input),
      nil
    )
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testParsingWithMissingKeyWithDefault() {
    let initialInput: JSONValue = [
      "first_name": "Steve",
      "age": 50,
    ]
    var input = initialInput

    XCTAssertEqual(
      try OptionalField("last_name", default: "Jobs") {
        String.jsonParser()
      }.parse(&input),
      "Jobs"
    )
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testFailedParsingAtKey() {
    let initialInput: JSONValue = [
      "first_name": "Steve",
      "age": 50,
    ]
    var input = initialInput

    XCTAssertThrowsError(
      try OptionalField("age") {
        String.jsonParser()
      }.parse(&input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At "age":
        Expected a string, but found:
        50
        """
      )
    }
    XCTAssertEqual(input, initialInput, "input should remain unchanged")
  }

  func testParsingWithNullValue() {
    let input: JSONValue = ["key": .null]

    XCTAssertNoThrow(try OptionalField("key") { Null() }.parse(input))
    XCTAssertEqual(
      try OptionalField("key", default: "default") { Null().map { "null" } }.parse(input),
      "default"
    )
    XCTAssertEqual(
      try OptionalField("key") { Int.jsonParser() }.parse(input),
      nil
    )
    XCTAssertEqual(
      try OptionalField("key", default: 0) { Int.jsonParser() }.parse(input),
      0
    )
  }

  func testParsingAndPrintingWithDefaultValue() {
    var input: JSONValue = [:]

    XCTAssertEqual(
      try OptionalField("some_key", default: 5) { Int.jsonParser() }.parse(&input),
      5
    )
    XCTAssertEqual(input, .object([:]))

    XCTAssertNoThrow(try OptionalField("some_key", default: 5) { Int.jsonParser() }.print(5, into: &input))
    XCTAssertEqual(input, .object([:]), "should not print defaultValue")

    XCTAssertNoThrow(try OptionalField("some_key", default: 5) { Int.jsonParser() }.print(6, into: &input))
    XCTAssertEqual(input, .object(["some_key": .integer(6)]))
  }

  func testParsingAndPrintingWithDefaultValueNoEquatable() {
    struct MyType {
      let value: Int

      static let jsonParser = Int.jsonParser().map(.memberwise(Self.init))
    }

    var input = JSONValue.object([:])

    XCTAssertEqual(
      try OptionalField("some_key", default: MyType(value: 5)) {
        MyType.jsonParser
      }.parse(&input).value,
      5
    )
    XCTAssertEqual(input, .object([:]))

    XCTAssertNoThrow(try OptionalField("some_key", default: MyType(value: 5)) {
      MyType.jsonParser
    }.print(MyType(value: 5), into: &input))
    XCTAssertEqual(
      input,
      .object(["some_key": .integer(5)]),
      "should be printed, since MyType is not Equatable"
    )

    XCTAssertNoThrow(try OptionalField("some_key", default: MyType(value: 5)) {
      MyType.jsonParser
    }.print(MyType(value: 6), into: &input))
    XCTAssertEqual(input, .object(["some_key": .integer(6)]))
  }

  func testPrintingIntoEmptyObject() {
    var input = JSONValue.empty

    XCTAssertNoThrow(
      try OptionalField("first_name") {
        String.jsonParser()
      }.print("Steve", into: &input)
    )
    XCTAssertEqual(input, .object(["first_name": .string("Steve")]))
  }

  func testPrintingIntoNonEmptyObject() {
    var input: JSONValue = [
      "first_name": "Steve",
    ]

    XCTAssertNoThrow(
      try OptionalField("age") {
        Int.jsonParser()
      }.print(50, into: &input)
    )
    XCTAssertEqual(
      input,
      [
        "first_name": "Steve",
        "age": 50,
      ]
    )
  }

  func testPrintingIntoNonObjectFailure() {
    var input: JSONValue = 10

    XCTAssertThrowsError(
      try OptionalField("key") {
        Int.jsonParser()
      }.print(5, into: &input)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        An OptionalField parser can only print to an object but attempted to print to:
        10
        """
      )
    }
    XCTAssertEqual(input, 10, "input should remain unchanged")
  }
}
