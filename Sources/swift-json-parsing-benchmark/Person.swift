import Foundation
import JSONParsing

// MARK: Model

struct Person: Codable {
  let name: String
  let age: Int
  let isAwesome: Bool
  let lifeStory: String
  let partner: String?
  let hobbies: [String]
}

// MARK: JSON parser

extension Person {
  static var jsonParser: some ParserPrinter<JSONValue, Self> {
    ParsePrint(.memberwise(Person.init)) {
      Field("name") { String.jsonParser() }
      Field("age") { Int.jsonParser() }
      Field("is_awesome") { Bool.jsonParser() }
      Field("life_story") { String.jsonParser() }
      OptionalField("partner") { String.jsonParser() }
      Field("hobbies") { JSONArray { String.jsonParser() } }
    }
  }
  static var jsonParserCombinedWithCodable: some ParserPrinter<JSONValue, Self> {
    ParsePrint(.memberwise(Person.init)) {
      Field("name") { String.jsonParser(decoder: .init()) }
      Field("age") { Int.jsonParser() }
      Field("is_awesome") { Bool.jsonParser() }
      Field("life_story") { String.jsonParser() }
      OptionalField("partner") { String.jsonParser() }
      Field("hobbies") { [String].jsonParser() }
    }
  }
}

// MARK: Bob

extension Person {
  static let bob = Person(
    name: "Bob Bobsson",
    age: 27,
    isAwesome: true,
    lifeStory: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et \"dolore\" magna aliqua.\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi utaliquip ex ea commodo consequat. Duis aute irure dolor inreprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat nonproident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\tUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi utaliquip ex ea commodo consequat. Duis aute irure dolor inreprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat nonproident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
    partner: nil,
    hobbies: ["fishing", "running", "football", "video games"]
  )
}
