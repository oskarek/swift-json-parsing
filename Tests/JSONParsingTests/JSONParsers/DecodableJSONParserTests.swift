@testable import JSONParsing
import Parsing
import XCTest

final class DecodableJSONParserTests: XCTestCase {
  func testSimpleDecoding() {
    struct Person: Equatable, Decodable {
      let firstName: String
      let age: Int
    }
    let json: JSONValue = [
      "firstName": "Steve",
      "age": 40,
    ]
    XCTAssertEqual(
      try Person.jsonParser().parse(json),
      .init(firstName: "Steve", age: 40)
    )
  }

  func testSimpleDecodingWithCustomJSONDecoder() {
    struct Person: Equatable, Decodable {
      let firstName: String
      let age: Int
    }
    let json: JSONValue = [
      "first_name": "Steve",
      "age": 40,
    ]
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    XCTAssertEqual(
      try Person.jsonParser(decoder: jsonDecoder).parse(json),
      .init(firstName: "Steve", age: 40)
    )
  }

  func testErrorMessageIntegrationWithParsingError() {
    struct Person: Decodable {
      let name: String
      let age: Int
      let hobbies: [String]
    }
    let json: JSONValue = [
      [
        "name": "Steve",
        "age": 40,
        "hobbies": ["reading", "football"],
      ],
      [
        "name": "Bob",
        "age": 55,
        "hobbies": [.null, "running"],
      ],
    ]
    XCTAssertThrowsError(
      try JSONArray { Person.jsonParser() }.parse(json)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At [index 1]/"hobbies"/[index 0]:
        (DecodingError) - Expected String but found null value instead.
        """
      )
    }
  }

  func testSimpleEncoding() {
    struct Person: Codable {
      let firstName: String
      let age: Int
    }
    let person = Person(firstName: "Steve", age: 40)
    let expectedJson: JSONValue = [
      "firstName": "Steve",
      "age": 40,
    ]
    XCTAssertEqual(
      try Person.jsonParser().print(person),
      expectedJson
    )
  }

  func testSimpleEncodingWithCustomJSONEncoder() {
    struct Person: Codable {
      let firstName: String
      let age: Int
    }
    let person = Person(firstName: "Steve", age: 40)
    let expectedJson: JSONValue = [
      "first_name": "Steve",
      "age": 40,
    ]
    let jsonEncoder = JSONEncoder()
    jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    XCTAssertEqual(
      try Person.jsonParser(encoder: jsonEncoder).print(person),
      expectedJson
    )
  }

  func testErrorMessageIntegrationWithPrintingError() {
    struct Person: Codable {
      struct Name: Codable {
        let value: String

        func encode(to encoder: Encoder) throws {
          let container = encoder.container(keyedBy: CodingKeys.self)
          throw EncodingError.invalidValue(
            value,
            .init(codingPath: container.codingPath, debugDescription: "Invalid value \"\(value)\".")
          )
        }
      }

      let name: Name
      let age: Int
    }
    let people = [
      Person(name: .init(value: "Alice"), age: 30),
      Person(name: .init(value: "Bob"), age: 45),
    ]
    let personParser = DecodableJSONParser<Person>()
    XCTAssertThrowsError(
      try JSONArray { personParser }.print(people)
    ) { error in
      XCTAssertEqual(
        "\(error)",
        """
        At [index 0]/"name":
        (EncodingError) - Invalid value "Alice".
        """
      )
    }
  }
}
