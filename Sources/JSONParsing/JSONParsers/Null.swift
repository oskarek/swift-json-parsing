import Foundation
import Parsing

/// A parser that attempts to parse a `null` json value. Only succeeds for the special json value `.null`, and returns nothing.
///
/// Using it looks like this:
///
/// ```swift
/// let json: JSONValue = .null
/// try Null().parse(json)   // ()
/// ```
public struct Null: ParserPrinter {
  /// Initializes a parser that attempts to parse a `null` json value.
  @inlinable
  public init() {}

  @inlinable
  public func parse(_ input: inout JSONValue) throws {
    guard case .null = input else {
      throw JSONParsingError.typeMismatch(expected: "a null value", got: input)
    }
    input = .empty
  }

  @inlinable
  public func print(_: (), into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("Null", got: input) }
    input = .null
  }
}
