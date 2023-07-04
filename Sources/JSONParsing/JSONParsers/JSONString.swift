import Foundation
import Parsing

/// A parser that tries to parse a json value by applying a string parser to it. Only succeeds if the json is in fact a string,
/// and the wrapped `stringParser` successfully parses it and _fully consumes it_ while doing so.
///
/// For example, here's how you can construct a json parser for a `Person` type that is encoded in json as a simple string,
/// with first and last name separated by a space:
///
/// ```swift
/// struct Person {
///   let firstName: String
///   let lastName: String
/// }
///
/// extension Person {
///   static let jsonParser = JSONString {
///     Parse(Person.init(firstName:lastName:)) {
///       Prefix { $0 != " " }.map(.string)
///       " "
///       Rest().map(.string)
///     }
///   }
/// }
/// ```
///
/// which then can be used like so:
///
/// ```swift
/// let json: JSONValue = "Steve Jobs"
/// let person = try Person.jsonParser.parse(json)
/// assert(person == Person(firstName: "Steve", lastName: "Jobs"))
/// ```
///
/// Even better, if the wrapped `stringParser` is a `ParserPrinter`, the `JSONString` is also a `ParserPrinter`.
/// In the example above, this can easily be achieved by just making use of the `.memberwise` conversion
/// from the `Parsing` library:
///
/// ```swift
/// let personParser = JSONString {
///   ParsePrint(.memberwise(Person.init(firstName:lastName:))) {
///     Prefix { $0 != " " }.map(.string)
///     " "
///     Rest().map(.string)
///   }
/// }
/// ```
/// And now it can be used to _print_ values of type `Person` back into a json string:
///
/// ```swift
/// let person = Person(firstName: "Tim", lastName: "Cook")
/// let json = try personParser.print(person)   // JSONValue
/// assert(json == .string("Tim Cook"))
/// ```
public struct JSONString<StringParser: Parser>: Parser where StringParser.Input == Substring {
  public let stringParser: StringParser

  /// Initializes a parser that tries to parse a json value by applying a string parser to it. Only succeeds if the json is in fact a string,
  /// and the given `stringParser` successfully parses it and _fully consumes it_ while doing so.
  ///
  /// For example, here's how you can construct json parser for a `Person` type:
  ///
  /// ```swift
  /// struct Person {
  ///   let firstName: String
  ///   let lastName: String
  /// }
  ///
  /// extension Person {
  ///   static let jsonParser = JSONString {
  ///     Parse(Person.init(firstName:lastName:)) {
  ///       Prefix { $0 != " " }.map(.string)
  ///       " "
  ///       Rest().map(.string)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// which then can be used like so:
  ///
  /// ```swift
  /// let json: JSONValue = "Steve Jobs"
  /// let person = try Person.jsonParser.parse(json)
  /// assert(person == Person(firstName: "Steve", lastName: "Jobs"))
  /// ```
  ///
  /// - Parameter stringParser: The parser to run on the json string.
  @inlinable
  public init(@ParserBuilder<Substring> stringParser: @escaping () -> StringParser) {
    self.stringParser = stringParser()
  }

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> StringParser.Output {
    guard case let .string(str) = input else {
      throw JSONParsingError.typeMismatch(expected: "a string", got: input)
    }
    let res = try stringParser.parse(Substring(str))
    input = .empty
    return res
  }
}

extension JSONString: ParserPrinter where StringParser: ParserPrinter {
  @inlinable
  public func print(_ output: StringParser.Output, into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("String", got: input) }
    input = try .string(.init(stringParser.print(output)))
  }
}

extension JSONString {
  /// Initializes a parser that tries to parse a json value by applying a string conversion to it. Only succeeds if the json is in fact a string,
  /// and the given conversion can be successfully applied on that string.
  ///
  /// For example, here's how you can construct a parser for parsing a custom enum with a `String` raw value, using the
  /// `.representing` conversion available from the `Parsing` library.:
  ///
  /// ```swift
  /// enum Direction: String {
  ///   case up, down, left, right
  /// }
  ///
  /// extension Direction {
  ///   static let jsonParser = JSONString(.representing(Direction.self))
  /// }
  ///
  /// let json: JSONValue = "left"
  /// let direction = try Direction.jsonParser.parse(json)
  /// assert(direction == .left)
  /// ```
  ///
  /// - Parameter conversion: A conversion to apply to the json string.
  @inlinable
  public init<C: Conversion<String, StringParser.Output>>(_ conversion: C)
  where StringParser ==
    Parsers.MapConversion<
      Parsers.ReplaceError<Rest<Substring>>,
      Conversions.Map<Conversions.SubstringToString, C>
    >
  {
    self.init { Rest().replaceError(with: "").map(.string.map(conversion)) }
  }

  /// Initializes a parser that tries to parse a json value as a string. Only succeeds if the json is in fact a string and,
  /// in that case, returns that string.
  ///
  /// Using it looks ike this:
  ///
  /// ```swift
  /// let json: JSONValue = "hello"
  /// let string = JSONString().parse(json)   // String
  /// assert(string == "hello")
  /// ```
  @inlinable
  public init()
  where StringParser ==
    Parsers.MapConversion<
      Parsers.ReplaceError<Rest<Substring>>,
      Conversions.SubstringToString
    >
  {
    self.init { Rest().replaceError(with: "").map(.string) }
  }
}

// MARK: String extension

extension String {
  /// A parser that can convert between `JSONValue` values and `String` values.
  /// Equivalent to using the empty initializer `JSONString.init()`.
  /// - Returns: A parser for converting between json and `String` values.
  @inlinable
  public static func jsonParser() ->
    JSONString<
      Parsers.MapConversion<
        Parsers.ReplaceError<Rest<Substring>>,
        Conversions.SubstringToString
      >
    >
  {
    JSONString()
  }
}
