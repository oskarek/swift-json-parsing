@testable import JSONParsing
import Parsing
import XCTest

final class SerializationTests: XCTestCase {
  func testParseAndPrintIntegerNumber() {
    let data = "128".data(using: .utf8)!
    let json: JSONValue = .integer(128)

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintFloatingPointNumber() {
    let data = "128.154".data(using: .utf8)!
    let json: JSONValue = .float(128.154)

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintNegativeNumber() {
    let data = "-14.0".data(using: .utf8)!
    let json: JSONValue = .float(-14.0)

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseNumbersWithScientificNotation() {
    XCTAssertEqual(try JSONValue("-14e-2".data(using: .utf8)!), .float(-0.14))
    XCTAssertEqual(try JSONValue("142.3e+2".data(using: .utf8)!), .float(14230))
    XCTAssertEqual(try JSONValue("1.5E-2".data(using: .utf8)!), .float(0.015))
    XCTAssertEqual(try JSONValue("0.45E+3".data(using: .utf8)!), .float(450))
  }

  func testParseAndPrintBooleanFalse() {
    let data = "false".data(using: .utf8)!
    let json: JSONValue = .boolean(false)

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintBooleanTrue() {
    let data = "true".data(using: .utf8)!
    let json: JSONValue = .boolean(true)

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintNull() {
    let data = "null".data(using: .utf8)!
    let json = JSONValue.null

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintSimpleUnescapedString() {
    let data = "\"abc 123\"".data(using: .utf8)!
    let json: JSONValue = .string("abc 123")

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try json.toJsonData(), data)
  }

  func testParseAndPrintStringWithEscapedChars() {
    let data = "\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"".data(using: .utf8)!
    let json: JSONValue = .string("\"\\/\u{8}\u{c}\n\r\t")

    XCTAssertEqual(try JSONValue(data), json)

    XCTAssertEqual(
      try String(data: json.toJsonData(), encoding: .utf8)!,
      String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\\/", with: "/"),
      "forward slash doesn't need escaping, the others does"
    )

    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  func testParseAndPrintStringWithUnicodeScalars() {
    let data = "\"\\u0031\\u0032\\u0033 \\u0061\\u0062\\u0063\"".data(using: .utf8)!
    let json: JSONValue = .string("123 abc")

    XCTAssertEqual(try JSONValue(data), json)

    XCTAssertEqual(
      try String(data: json.toJsonData(), encoding: .utf8),
      "\"123 abc\"",
      "should not print back with unicode scalars"
    )

    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  func testParseAndPrintStringWithSurrogatePair() {
    let data = "\"\\uD834\\uDD1E\"".data(using: .utf8)!
    let json = JSONValue.string("𝄞")

    XCTAssertEqual(try JSONValue(data), json)

    XCTAssertEqual(
      try String(data: json.toJsonData(), encoding: .utf8),
      "\"𝄞\"",
      "should not print back as a surrogate pair"
    )

    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  func testParseAndPrintComplexString() {
    let data = "\"abc 123\\u0034\\u0035 \\uD834\\uDD1E 🎉:\\thello\"".data(using: .utf8)!
    let json = JSONValue.string("abc 12345 𝄞 🎉:\thello")

    XCTAssertEqual(try JSONValue(data), json)

    XCTAssertEqual(
      try String(data: json.toJsonData(), encoding: .utf8),
      "\"abc 12345 𝄞 🎉:\\thello\""
    )

    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  func testParseAndPrintArray() {
    let data = """
    [
      1,
      -15,
      2000,
      0
    ]
    """.data(using: .utf8)!

    let json = JSONValue.array([
      .integer(1),
      .integer(-15),
      .integer(2000),
      .integer(0),
    ])

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(try String(data: json.toJsonData(), encoding: .utf8), "[1,-15,2000,0]")
    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  func testParseAndPrintObject() {
    let data = """
    {
      "a": null,
      "b": false,
      "c": 3,
      "d": 6.5,
      "e": 10.0,
      "f": "a string",
      "g": [false, true]
    }
    """.data(using: .utf8)!

    let json = JSONValue.object([
      "a": .null,
      "b": .boolean(false),
      "c": .integer(3),
      "d": .float(6.5),
      "e": .float(10.0),
      "f": .string("a string"),
      "g": .array([.boolean(false), .boolean(true)]),
    ])

    XCTAssertEqual(try JSONValue(data), json)
    XCTAssertEqual(
      try String(data: json.toJsonData(), encoding: .utf8),
      """
      {"a":null,"b":false,"c":3,"d":6.5,"e":10.0,"f":"a string","g":[false,true]}
      """
    )
    XCTAssertEqual(try JSONValue(json.toJsonData()), json, "roundtrip property")
  }

  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  func testJSON5() {
    let data = """
    {
      "a": null, // a comment
      "b": false,
      "c": 3,
      "d": 6.5,
      "e": 10.0,
      "f": "a string",
      "g": [false, true,],
    }
    """.data(using: .utf8)!

    let json = JSONValue.object([
      "a": .null,
      "b": .boolean(false),
      "c": .integer(3),
      "d": .float(6.5),
      "e": .float(10.0),
      "f": .string("a string"),
      "g": .array([.boolean(false), .boolean(true)]),
    ])

    XCTAssertEqual(try JSONValue(data, allowJSON5: true), json)
  }

  func testParseEmptyObject() {
    let data = "{}".data(using: .utf8)!
    XCTAssertEqual(try JSONValue(data), .empty)
  }

  func testParseEmptyStringShouldFail() {
    let data = "".data(using: .utf8)!
    XCTAssertThrowsError(try JSONValue(data)) { error in
      XCTAssertEqual(
        "\(error)",
        "Unable to parse empty data."
      )
    }
  }

  func testSerializeInfiniteNumberShouldFail() {
    let json: JSONValue = .float(.infinity)
    XCTAssertThrowsError(try json.toJsonData()) { error in
      XCTAssertEqual(
        "\(error)",
        "Can't serialize JSONValue containing an infinite number."
      )
    }
  }

  func testSerializeNaNNumberShouldFail() {
    let json: JSONValue = .float(.nan)
    XCTAssertThrowsError(try json.toJsonData()) { error in
      XCTAssertEqual(
        "\(error)",
        "Can't serialize JSONValue containing a NaN number."
      )
    }
  }

  func testParseOverflowedIntShouldBecomeFloat() {
    let data1 = "-9223372036854775809".data(using: .utf8)!
    let data2 = "-9223372036854775808".data(using: .utf8)!
    let data3 = "9223372036854775807".data(using: .utf8)!
    let data4 = "9223372036854775808".data(using: .utf8)!
    XCTAssertEqual(try JSONValue(data1), .float(Double(Int.min) - 1))
    XCTAssertEqual(try JSONValue(data2), .integer(.min))
    XCTAssertEqual(try JSONValue(data3), .integer(.max))
    XCTAssertEqual(try JSONValue(data4), .float(Double(Int.max) + 1))
  }
}
