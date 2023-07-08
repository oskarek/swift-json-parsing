import Foundation
import Parsing

/// A parser that, like the ``Field`` parser, tries to parse off a single field from a json object.
/// But unlike the `Field` parser, it allows for the field to _not exists_, in which case it just
/// returns `nil` or a `default` value if one is provided. Just like the `Field` parser it will,
/// if successful, remove the field (if existent) from the input json.
///
/// **Note: the `OptionalField` parser treats a field with an explicit `null` value as non-existent.**
///
/// Let's extend the example from the ``Field`` parser documentation, by adding a new optional field
/// `"salary"` to the person json, and see how the `OptionalField` parser can be used to parse it:
///
/// ```swift
/// struct Person {
///   let firstName: String
///   let lastName: String
///   let age: Int
///   let salary: Int?
/// }
///
/// extension Person {
///   static let jsonParser = ParsePrint(.memberwise(Person.init(firstName:lastName:age:salary:))) {
///     Field("firstName") { String.jsonParser() }
///     Field("lastName") { String.jsonParser() }
///     Field("age") { Int.jsonParser() }
///     OptionalField("salary") { Int.jsonParser() }
///   }
/// }
/// ```
///
/// Now, if the json contains a `"salary"` field, this will be parsed and stored as salary in the
/// `Person` object:
///
/// ```swift
/// let personJsonWithSalary: JSONValue = .object([
///   "firstName": "Steve",
///   "lastName": "Jobs",
///   "age": 56,
///   "salary": 100_000,
/// ])
///
/// let person = try Person.jsonParser.parse(personJsonWithSalary)
/// assert(person == Person(firstName: "Steve", lastName: "Jobs", age: 56, salary: 100_000))
/// ```
///
/// And if the json lacks a `"salary"` field (or if it is `null`), parsing will still succeed and
/// `nil` will be used:
///
/// ```swift
/// let personJsonWithoutSalary = JSONValue.object([
///   "firstName": .string("Steve"),
///   "lastName": .string("Jobs"),
///   "age": .integer(56),
///            // <--- or: "salary": .null,
/// ])
///
/// let person = try Person.jsonParser.parse(personJsonWithoutSalary)
/// assert(person == Person(firstName: "Steve", lastName: "Jobs", age: 56, salary: nil))
/// ```
///
/// If instead of `nil`, you want to use a default value when the field is missing, it can be accomplished like this:
///
/// ```swift
/// struct Person {
///   let firstName: String
///   let lastName: String
///   let age: Int
///   let salary: Int   // note: salary is now non-optional
/// }
///
/// extension Person {
///   static let jsonParser = ParsePrint(.memberwise(Person.init(firstName:lastName:age:salary:))) {
///     Field("firstName") { String.jsonParser() }
///     Field("lastName") { String.jsonParser() }
///     Field("age") { Int.jsonParser() }
///     OptionalField("salary", default: 0) { Int.jsonParser() }
///   }
/// }
///
/// let person = try Person.jsonParser.parse(personJsonWithoutSalary)
/// assert(person == Person(firstName: "Steve", lastName: "Jobs", age: 56, salary: 0))
/// ```
public struct OptionalField<Value: Parser, Output>: Parser where Value.Input == JSONValue {
  /// The key of the field to parse.
  public let key: String
  /// The parser to apply to the value of the field, if it exists.
  public let valueParser: Value

  @usableFromInline
  let toOutput: (Value.Output?) -> Output
  @usableFromInline
  let fromOutput: (Output) -> Value.Output?

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> Output {
    guard case var .object(dictionary) = input else {
      throw JSONParsingError.typeMismatch(expected: "an object", got: input)
    }
    guard let value = dictionary[key], value != .null else {
      dictionary.removeValue(forKey: key)
      return toOutput(nil)
    }
    do {
      let output = try valueParser.parse(value)
      dictionary.removeValue(forKey: key)
      input = .object(dictionary)
      return toOutput(output)
    } catch {
      throw JSONParsingError.failureInObject(atKey: key, error)
    }
  }
}

extension OptionalField: ParserPrinter where Value: ParserPrinter {
  @inlinable
  public func print(_ output: Output, into input: inout JSONValue) throws {
    guard case var .object(dictionary) = input else {
      throw JSONPrintingError.typeMismatch("OptionalField", expected: "an object", got: input)
    }
    guard let output = fromOutput(output) else { return }
    do {
      dictionary[key] = try valueParser.print(output)
      input = .object(dictionary)
    } catch {
      throw JSONPrintingError.failureInObject(atKey: key, error)
    }
  }
}

extension OptionalField {
  /// Initializes a parser that tries to parse off a single field from a json object. If the field
  /// doesn't exist, `nil` is returned instead.
  ///
  /// This is how to use it for parsing:
  ///
  /// ```swift
  /// let json: JSONValue = .object([
  ///   "key_1": 10,
  ///   "key_2": "hello",
  /// ])
  ///
  /// try OptionalField("key_1") { Int.jsonParser() }.parse(json)
  /// // returns: 10 as Int?
  ///
  /// try OptionalField("key_1") { Bool.jsonParser() }.parse(json)
  /// // error: Expected a boolean, but found:
  /// // 10
  ///
  /// try OptionalField("inexistent_key") { Int.jsonParser() }.parse(json)
  /// // returns: nil
  /// ```
  ///
  /// And it can be used for printing too, as long as the `valueParser` is a printer:
  ///
  /// ```swift
  /// try OptionalField("key_1") { Int.jsonParser() }.print(10)
  /// // returns: JSONValue.object([
  /// //   "key_1": .integer(10)
  /// // ])
  ///
  /// try OptionalField("key_1") { Int.jsonParser() }.print(nil)
  /// // returns: .object([:])
  /// ```
  ///
  /// - Parameters:
  ///   - key: The key of the field to parse off the json.
  ///   - valueParser: The parser to apply to the value of the field.
  @inlinable
  public init(
    _ key: String,
    @ParserBuilder<JSONValue> valueParser: @escaping () -> Value
  ) where Output == Value.Output? {
    self.key = key
    self.valueParser = valueParser()
    self.toOutput = { $0 }
    self.fromOutput = { $0 }
  }

  /// Initializes a parser that tries to parse off a single field from a json object. If the field
  /// doesn't exist, the provided `defaultValue` is used instead.
  ///
  /// This is how to use it for parsing:
  ///
  /// ```swift
  /// let json: JSONValue = .object([
  ///   "key_1": 10,
  ///   "key_2": "hello",
  /// ])
  ///
  /// try OptionalField("key_1", default: 0) { Int.jsonParser() }.parse(json)
  /// // returns: 10
  ///
  /// try OptionalField("key_1", default: false) { Bool.jsonParser() }.parse(json)
  /// // error: Expected a boolean, but found:
  /// // 10
  ///
  /// try OptionalField("inexistent_key", default: 0) { Int.jsonParser() }.parse(json)
  /// // returns: 0
  /// ```
  ///
  /// And it can be used for printing too, as long as the `valueParser` is a printer:
  ///
  /// ```swift
  /// try OptionalField("key_1", default: 0) { Int.jsonParser() }.print(10)
  /// // returns: JSONValue.object([
  /// //   "key_1": .integer(10)
  /// // ])
  ///
  /// try OptionalField("key_1", default: 0) { Int.jsonParser() }.print(0)
  /// // returns: .object([:])
  /// ```
  ///
  /// Notable in the example above is the fact that the `0` value is not printed. That is because it's equal
  /// to the specified `defaultValue` of the parser. Whenever that is the case, the value is not printed.
  /// ```
  ///
  /// - Parameters:
  ///   - key: The key of the field to parse off the json.
  ///   - defaultValue: The value to use if the field is not present.
  ///   - valueParser: The parser to apply to the value of the field.
  @inlinable
  public init(
    _ key: String,
    default defaultValue: Value.Output,
    @ParserBuilder<JSONValue> valueParser: @escaping () -> Value
  ) where Output == Value.Output, Output: Equatable {
    self.key = key
    self.valueParser = valueParser()
    self.toOutput = { $0 ?? defaultValue }
    self.fromOutput = { $0 == defaultValue ? nil : $0 }
  }

  /// Initializes a parser that tries to parse off a single field from a json object. If the field
  /// doesn't exist, the provided `defaultValue` is used instead.
  ///
  /// **Note: if this overload of the initializer is used, it means the `Output` type
  /// is not `Equatable`, which leads to slightly different behavior when used as a printer.
  /// More on that below.**
  ///
  /// This is how to use it for parsing:
  ///
  /// ```swift
  /// // note: no Equatable conformance
  /// struct MyType {
  ///   let value: Int
  /// }
  /// extension MyType {
  ///   static let jsonParser = Int.jsonParser().map(.memberwise(Self.init))
  /// }
  ///
  /// let json: JSONValue = .object([
  ///   "key_1": 10,
  ///   "key_2": "hello",
  /// ])
  ///
  /// try OptionalField("key_1", default: MyType(value: 0)) {
  ///   MyType.jsonParser
  /// }.parse(json)
  /// // returns: MyType(value: 10)
  ///
  /// try OptionalField("key_2", default: MyType(value: 0)) {
  ///   MyType.jsonParser
  /// }.parse(json)
  /// // error: Expected a number, but found:
  /// // "hello"
  ///
  /// try OptionalField("inexistent_key", default: MyType(value: 0)) {
  ///   MyType.jsonParser
  /// }.parse(json)
  /// // returns: MyType(value: 0)
  /// ```
  ///
  /// And it can be used for printing too, as long as the `valueParser` is a printer:
  ///
  /// ```swift
  /// try OptionalField("key_1", default: MyType(value: 0)) {
  ///   MyValue.jsonParser
  /// }.print(MyType(value: 10))
  /// // returns: JSONValue.object([
  /// //   "key_1": .integer(10)
  /// // ])
  ///
  /// try OptionalField("key_1", default: MyType(value: 0)) {
  ///   MyValue.jsonParser
  /// }.print(MyType(value: 0))
  /// // returns: JSONValue.object([
  /// //   "key_1": .integer(0)
  /// // ])
  /// ```
  ///
  /// Notable in the example above is the fact that the `MyValue(value: 0)` value _is_ printed.
  /// If `MyType` would have conformed to `Equatable`, that would not have been the case,
  /// because then it could have been determined that it was equal to the `defaultValue` and therefore
  /// does not have to be printed. So if you want to omit printing the default value, make sure your `Output`
  /// type conforms to `Equatable`.
  ///
  /// - Parameters:
  ///   - key: The key of the field to parse off the json.
  ///   - defaultValue: The value to use if the field is not present.
  ///   - valueParser: The parser to apply to the value of the field.
  @_disfavoredOverload
  @inlinable
  public init(
    _ key: String,
    default defaultValue: Value.Output,
    @ParserBuilder<JSONValue> valueParser: @escaping () -> Value
  ) where Output == Value.Output {
    self.key = key
    self.valueParser = valueParser()
    self.toOutput = { $0 ?? defaultValue }
    self.fromOutput = { $0 }
  }
}
