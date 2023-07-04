import Foundation
import Parsing

/// A parser that tries to parse a json value as an array.
///
/// For example, parsing a json array of strings looks like this:
///
/// ```swift
/// let json: JSONValue = .array(["one", "two", "three"])
/// let parser = JSONArray {
///   String.jsonParser()
/// }
/// let array = try parser.parse(json)   // [String]
/// assert(array == ["one", "two", "three"])
/// ```
///
/// Since the wrapped `elementParser` in this example is a `ParserPrinter`, the `JSONArray` parser is also a `ParserPrinter`
/// and can be used to print array values into json arrays:
///
/// ```swift
/// let array = ["alpha", "beta", "gamma"]
/// let json = try parser.print(array)   // JSONValue
/// assert(json == .array(["alpha", "beta", "gamma"]))
/// ```
public struct JSONArray<Element: Parser>: Parser where Element.Input == JSONValue {
  /// The parser to apply to each element in the array.
  public let elementParser: Element
  /// The maximum number of elements allowed.
  public let maximum: Int?
  /// The minimum number of elements allowed.
  public let minimum: Int

  // Error output helpers

  @usableFromInline func isOutOfRange(_ value: Int) -> Bool {
    value < minimum || maximum.map { value > $0 } ?? false
  }
  @usableFromInline var rangeString: String {
    guard let maximum else { return "at least \(minimum)" }
    return "\(minimum)" + (maximum > minimum ? "-\(maximum)" : "")
  }
  @usableFromInline var rangeSuffix: String {
    "element" + (minimum == 1 && [nil, minimum].contains(maximum) ? "" : "s")
  }

  /// Initialize a parser that tries to parse a json value as an array.
  ///
  /// The optional `range` parameter can be used to limit the allowed length of the json array.
  ///
  /// For example, this is how you can construct a parser of _non-empty_ json arrays of integer numbers:
  ///
  /// ```swift
  /// let parser = JSONArray(1...) {
  ///   Int.jsonParser()
  /// }
  /// ```
  ///
  /// Using this to parse a json array that turns out to be empty would throw an error:
  ///
  /// ```swift
  /// let json: JSONValue = []
  /// try parser.parse(json)
  /// // error: Expected at least 1 element in array but there were 0.
  /// ```
  ///
  /// - Parameters:
  ///   - range: A range that decides the minimum and maximum length of the json array. Any length outside this range will cause parsing to fail.
  ///   - elementParser: The parser to run on each element in the json array.
  @inlinable
  public init<R: CountingRange>(
    _ range: R = 0...,
    @ParserBuilder<JSONValue> elementParser: @escaping () -> Element
  ) {
    self.elementParser = elementParser()
    self.maximum = range.maximum
    self.minimum = range.minimum
  }

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> [Element.Output] {
    guard case let .array(array) = input else {
      throw JSONParsingError.typeMismatch(expected: "an array", got: input)
    }

    if isOutOfRange(array.count) {
      throw JSONParsingError.failure(
        "Expected \(rangeString) \(rangeSuffix) in array, but found \(array.count)."
      )
    }

    let outputList = try array.enumerated().map { index, element in
      do {
        return try elementParser.parse(element)
      } catch {
        throw JSONParsingError.failureInArray(atIndex: index, error)
      }
    }
    input = .empty
    return outputList
  }
}

extension JSONArray: ParserPrinter where Element: ParserPrinter {
  @inlinable
  public func print(_ output: [Element.Output], into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("Array", got: input) }

    if isOutOfRange(output.count) {
      throw JSONParsingError.failure(
        "An Array parser requiring \(rangeString) \(rangeSuffix) was given \(output.count) to print."
      )
    }

    input = try .array(
      output.enumerated().map { index, element in
        do {
          return try elementParser.print(element)
        } catch {
          throw JSONPrintingError.failureInArray(atIndex: index, error)
        }
      }
    )
  }
}
