import Foundation
import Parsing

/// A parser that attempts to parse a json value as a boolean. Can also alternatively
/// be constructed via `Bool.jsonParser()`.
///
/// Using it to parse a json boolean into a `Bool` looks like this:
///
/// ```swift
/// let json: JSONValue = .boolean(false)
/// let bool = try JSONBoolean().parse(json)   // Bool
/// assert(bool == false)
/// ```
///
/// It can also be used as a printer:
///
/// ```swift
/// let bool = true
/// let json = try JSONBoolean().print(bool)   // JSONValue
/// assert(json == .boolean(true))
/// ```
public struct JSONBoolean: ParserPrinter {
  /// Initializes a parser that attempts to parse a json value as a boolean.
  ///
  /// Using it looks like this:
  ///
  /// ```swift
  /// let json: JSONValue = .boolean(false)
  /// let bool = try JSONBoolean().parse(json)   // Bool
  /// assert(bool == false)
  @inlinable
  public init() {}

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> Swift.Bool {
    guard case let .boolean(bool) = input else {
      throw JSONParsingError.typeMismatch(expected: "a boolean", got: input)
    }
    input = .empty
    return bool
  }

  @inlinable
  public func print(_ output: Swift.Bool, into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("JSONBoolean", got: input) }
    input = .boolean(output)
  }
}

// MARK: Bool extension

extension Bool {
  /// A parser that can convert between `JSONValue` values and `Bool` values.
  /// Equivalent to `JSONBoolean()`.
  /// - Returns: A parser for converting between json and `Bool` values.
  @inlinable
  public static func jsonParser() -> JSONBoolean {
    .init()
  }
}
