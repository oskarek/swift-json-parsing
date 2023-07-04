import Foundation
import Parsing

/// A parser that tries to parse off a single field from a json object. The parser, if succesful, will remove the field from the input json,
/// so that it can then be further parsed by other parsers.
///
/// For example, here's how to work with a json value that encodes a person. First, let's see how a single `Field` parser
/// can extract just the `firstName` field from the json:
///
/// ```swift
/// var personJson: JSONValue = .object([
///   "first_name": "Steve",
///   "last_name": "Jobs",
///   "age": 56,
/// ])
/// let firstNameParser = Field("first_name") {
///   String.jsonParser()
/// }
/// let firstName = try firstNameParser.parse(&personJson)   // String
/// assert(firstName == "Steve")
/// assert(
///   personJson ==
///   .object([
///     "last_name": "Jobs",
///     "age": 56,
///   ])
/// )
/// ```
///
/// But in this case, as in many other cases, you probably want to combine multiple `Field` parsers together to parse
/// the entire json into a `Person` type:
///
/// ```swift
/// struct Person {
///   let firstName: String
///   let lastName: String
///   let age: Int
/// }
///
/// extension Person {
///   static let jsonParser = Parse(Person.init(firstName:lastName:age:)) {
///     Field("first_name") { String.jsonParser() }
///     Field("last_name") { String.jsonParser() }
///     Field("age") { Int.jsonParser() }
///   }
/// }
///
/// let person = try Person.jsonParser.parse(&personJson)
/// assert(person == Person(firstName: "Steve", lastName: "Jobs", age: 56))
/// assert(personJson == JSONValue.empty)
/// ```
///
/// Also, the `Field` parser can work as a printer if the wrapped `valueParser` is a printer. In the above example,
/// all `Field` parsers are already printers, and the combined person parser can be turned into one very easily with
/// just a couple small tweaks:
///
/// ```swift
/// extension Person {
///   static let jsonParser = ParsePrint(.memberwise(Person.init(firstName:lastName:age:))) {
///     Field("first_name") { String.jsonParser() }
///     Field("last_name") { String.jsonParser() }
///     Field("age") { Int.jsonParser() }
///   }
/// }
/// ```
///
/// Now, it can be used to turn `Person` values back into json:
///
/// ```swift
/// let person = Person(firstName: "Tim", lastName: "Cook", age: 62)
/// let json = try personParser.print(person)
/// assert(
///   json ==
///   .object([
///     "first_name": "Tim",
///     "last_name": "Cook",
///     "age": 62,
///   ])
/// )
/// ```
public struct Field<Value: Parser>: Parser where Value.Input == JSONValue {
  /// The key of the field to parse.
  public let key: String
  /// The parser to apply to the value of the field.
  public let valueParser: Value

  /// Initializes a parser that tries to parse off a single field from a json object. The parser, if succesful, will remove the field from
  /// the input json, so that it can then be further parsed by other parsers.
  ///
  /// Here's how it can be used to parse the individual fields of a json representing a `Person`:
  ///
  /// ```swift
  /// struct Person {
  ///   let firstName: String
  ///   let lastName: String
  ///   let age: Int
  /// }
  ///
  /// extension Person {
  ///   static let jsonParser = ParsePrint(.memberwise(Person.init(firstName:lastName:age:))) {
  ///     Field("first_name") { String.jsonParser() }
  ///     Field("last_name") { String.jsonParser() }
  ///     Field("age") { Int.jsonParser() }
  ///   }
  /// }
  ///
  /// var personJson: JSONValue = .object([
  ///   "first_name": "Steve",
  ///   "last_name": "Jobs",
  ///   "age": 56,
  /// ])
  ///
  /// let person = try Person.jsonParser.parse(&personJson)
  /// assert(person == Person(firstName: "Steve", lastName: "Jobs", age: 56))
  /// assert(personJson == JSONValue.empty)
  /// ```
  ///
  /// And since the above parser is also a printer, it can be used to turn `Person` values back into json:
  ///
  /// ```swift
  /// let person = Person(firstName: "Tim", lastName: "Cook", age: 62)
  /// let json = try personParser.print(person)
  /// assert(
  ///   json ==
  ///   .object([
  ///     "first_name": .string("Tim"),
  ///     "last_name": .string("Cook"),
  ///     "age": .integer(62),
  ///   ])
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - key: The key of the field to parse off the json.
  ///   - valueParser: The parser to apply to the value of the field.
  @inlinable
  public init(_ key: String, @ParserBuilder<JSONValue> valueParser: @escaping () -> Value) {
    self.key = key
    self.valueParser = valueParser()
  }

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> Value.Output {
    guard case var .object(dictionary) = input else {
      throw JSONParsingError.typeMismatch(expected: "an object (containing the key \"\(key)\")", got: input)
    }
    guard var value = dictionary[key] else {
      throw JSONParsingError.failure("Key \"\(key)\" not present.")
    }
    do {
      let output = try valueParser.parse(&value)
      dictionary[key] = value == .empty ? nil : value
      input = .object(dictionary)
      return output
    } catch {
      throw JSONParsingError.failureInObject(atKey: key, error)
    }
  }
}

extension Field: ParserPrinter where Value: ParserPrinter {
  @inlinable
  public func print(_ output: Value.Output, into input: inout JSONValue) throws {
    guard case var .object(dictionary) = input else {
      throw JSONPrintingError.typeMismatch("Field", expected: "an object", got: input)
    }
    do {
      dictionary[key] = try valueParser.print(output)
      input = .object(dictionary)
    } catch {
      throw JSONPrintingError.failureInObject(atKey: key, error)
    }
  }
}

extension Field where Value == Parsers.Conditional<Always<JSONValue, Void>, Not<JSONValue, Null>> {
  /// Initialize a parser that parses off a single field from a json value, ignores its value and just returns `Void`.
  ///
  /// This can be useful when you only want to make sure a certain field exists, but don't care about it's value.
  ///
  /// **Note**: The default behavior is to _not allow_ an explicit `null` value in the field. If that's not what you want,
  /// pass `true` to the optional `allowNull` parameter.
  ///
  /// - Parameters:
  ///   - key: The key of the field to parse off the json.
  ///   - acceptNull: Determines whether or not an explicit `null` value is allowed for the field. Default is `false`.
  @inlinable
  public init(_ key: String, allowNull: Bool = false) {
    self.init(key) {
      if allowNull {
        Always(())
      } else {
        Not { Null() }
      }
    }
  }
}
