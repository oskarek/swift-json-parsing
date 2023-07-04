@testable import JSONParsing
import Parsing
import XCTest

final class PrettyPrintingTests: XCTestCase {
  func testMaxDepth0() {
    let json = JSONValue.object([
      "key1": .boolean(true),
      "key2": .string("hello"),
      "key3": .object([
        "subkey": .integer(3),
      ]),
    ])
    XCTAssertEqual(json.prettyPrinted(maxDepth: 0), "{ ...(+3 more) }")
  }

  func testMaxDepth0FitsOnOneLine() {
    let json = JSONValue.object([
      "a": .boolean(true),
    ])
    XCTAssertEqual(json.prettyPrinted(maxDepth: 0), "{ \"a\": true }")
  }

  func testMaxSubvalueCount0() {
    let json = JSONValue.object([
      "key1": .boolean(true),
      "key2": .string("hello"),
      "key3": .object([
        "subkey": .integer(3),
      ]),
    ])
    XCTAssertEqual(json.prettyPrinted(maxSubValueCount: 0), "{ ...(+3 more) }")
  }

  func testNestedJSONPrintingWithCustomization() {
    let json = JSONValue.object([
      "a": .boolean(true),
      "b": .string("a quite long string\nthat spans multiple lines\nand exceeds the max length"),
      "c": .object([
        "1": .object([
          "x": .boolean(false),
          "y": .string("hi"),
          "z": .integer(2),
        ]),
        "2": .string("a long string that contains no newlines but does exceed the max length"),
        "3": .array([
          .integer(1),
          .integer(2),
          .integer(3),
          .string("four"),
        ]),
        "4": .integer(3),
      ]),
      "d": .boolean(false),
      "e": .float(15.0),
    ])
    XCTAssertEqual(
      json.prettyPrinted(maxDepth: 2, maxSubValueCount: 3, maxStringLength: 60, indentationString: " "),
      """
      {
       "a": true,
       "b": \"\"\"
        a quite long string
        that spans multiple ...(+32 more chars)
        \"\"\",
       "c": {
        "1": { ...(+3 more) },
        "2": "a long string that contains no newlines ...(+30 more chars)",
        "3": [ 1, 2, 3, "four" ],
        ...(+1 more)
       },
       ...(+2 more)
      }
      """
    )
  }

  func testNestedJSONPrintingWithDefaultConfig() {
    let json = JSONValue.object([
      "a": .boolean(true),
      "b": .string("a quite long string\nthat spans multiple lines\nand will be shown in its entirety"),
      "c": .object([
        "1": .object([
          "x": .boolean(false),
          "y": .string("hi"),
          "z": .integer(2),
        ]),
        "2": .string("a long string that contains no newlines and will be shown in its entirety"),
        "3": .array([
          .integer(1),
          .integer(2),
          .integer(3),
          .string("four"),
        ]),
        "4": .integer(3),
      ]),
      "d": .boolean(false),
      "e": .float(15.0),
    ])
    XCTAssertEqual(
      json.prettyPrinted(),
      """
      {
        "a": true,
        "b": \"\"\"
          a quite long string
          that spans multiple lines
          and will be shown in its entirety
          \"\"\",
        "c": {
          "1": {
            "x": false,
            "y": "hi",
            "z": 2
          },
          "2": "a long string that contains no newlines and will be shown in its entirety",
          "3": [ 1, 2, 3, "four" ],
          "4": 3
        },
        "d": false,
        "e": 15.0
      }
      """
    )
  }
}
