import Foundation
import Parsing

/// A parser that attempts to parse a json value as a number. Can also alternatively
/// be constructed via the static `jsonParser()` method available on all `BinaryInteger`
/// and `BinaryFloatingPoint` types, for example `Int.jsonParser()`.
///
/// For example, to parse a json value as an `Int`, you do:
///
/// ```swift
/// let json: JSONValue = .integer(3)
/// let num = try JSONNumber<Int>().parse(json)   // Int
/// assert(num == 3)
/// ```
///
/// It can also be used as a printer:
///
/// ```swift
/// let num: Int = 10
/// let json = try JSONNumber<Int>().print(num)   // JSONValue
/// assert(json == .integer(10))
/// ```
public struct JSONNumber<Num>: ParserPrinter {
  @usableFromInline
  enum `Type` {
    case float(fromDouble: (Double) -> Num, toDouble: (Num) -> Double, fromInt: ((Int) -> Num)?)
    case integer(fromInt: (Int) -> Num, toInt: (Num) -> Int)
  }

  @usableFromInline
  let type: `Type`

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> Num {
    switch (type, input) {
    case let (.float(fromDouble, _, _), .float(double)):
      input = .empty
      return fromDouble(double)
    case let (.float(_, _, fromInt?), .integer(int)):
      input = .empty
      return fromInt(int)
    case let (.float(_, _, fromInt), _):
      let expected = fromInt == nil ? "a floating point number" : "a number"
      throw JSONParsingError.typeMismatch(expected: expected, got: input)

    case let (.integer(fromInt, _), .integer(int)):
      input = .empty
      return fromInt(int)
    case (.integer, _):
      throw JSONParsingError.typeMismatch(expected: "an integer number", got: input)
    }
  }

  @inlinable
  public func print(_ output: Num, into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("JSONNumber", got: input) }
    switch type {
    case let .float(_, toDouble, _):
      input = .float(toDouble(output))
    case let .integer(_, toInt):
      input = .integer(toInt(output))
    }
  }
}

extension JSONNumber where Num: BinaryInteger {
  /// Initialize a `JSONNumber` parser that will attempt to parse a json value as an integer number.
  ///
  /// For example:
  ///
  /// ```swift
  /// let json = JSONValue.integer(3)
  /// let num = try JSONNumber<Int>().parse(json)
  /// assert(num == 3)
  /// ```
  @inlinable
  public init() { self = .integer() }

  @usableFromInline
  static func integer() -> Self {
    .init(type: .integer(fromInt: { Num($0) }, toInt: { Int($0) }))
  }
}

extension JSONNumber where Num: BinaryFloatingPoint {
  /// Initialize a `JSONNumber` parser that will attempt to parse a json value as an floating point number.
  /// The optional `allowInteger` parameter determines if it should allow integer values or not.
  ///
  /// It is used like this:
  ///
  /// ```swift
  /// let json = JSONValue.integer(5)
  ///
  /// try JSONNumber<Double>().parse(json) // 5.0
  /// try JSONNumber<Double>(allowInteger: false).parse(json)
  /// // error: Expected a floating point number, but found 5
  /// ```
  ///
  /// - Parameter allowInteger: If `false`, the parser will fail on integer numbers, if `true` _any_ number
  /// is permitted, including integers, which would then be _cast_ to a floating point. Default is `true`.
  @inlinable
  public init(allowInteger: Bool = true) { self = .float(allowInteger: allowInteger) }

  @usableFromInline
  static func float(allowInteger: Bool = true) -> Self {
    .init(
      type: .float(
        fromDouble: { Num($0) },
        toDouble: { Double($0) },
        fromInt: allowInteger ? Num.init : nil
      )
    )
  }
}

// MARK: JSONNumber type extensions

extension BinaryInteger {
  /// A parser that can convert between `JSONValue` values and integer values.
  /// Equivalent to using the empty initializer `JSONNumber<Self>.init()`.
  /// - Returns: A parser for converting between json and integer values.
  @inlinable
  public static func jsonParser() -> JSONNumber<Self> {
    .init()
  }
}

extension BinaryFloatingPoint {
  /// A parser that can convert between `JSONValue` values and floating point values.
  /// Equivalent to using the initializer `JSONNumber<Self>.init(allowInteger:)`.
  /// - Returns: A parser for converting between json and floating point values.
  @inlinable
  public static func jsonParser(allowInteger: Bool = true) -> JSONNumber<Self> {
    .init(allowInteger: allowInteger)
  }
}
