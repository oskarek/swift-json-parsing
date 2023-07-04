import Foundation
import Parsing

extension Date {
  /// A parser that can convert between `String` and `Date` values, using an given `DateFormatter`.
  ///
  /// - Parameter style: The formatter to use for converting between strings and `Date` values.
  /// - Returns: A parser for converting between strings and `Date` values, using a `DateFormatter`.
  public static func parser(formatter: DateFormatter) -> DateParser {
    .init(parseDate: formatter.date(from:), formatDate: formatter.string(from:))
  }

  /// A parser that can convert between `JSONValue` values and `Date` values, using an given `DateFormatter`.
  ///
  /// - Parameter style: The formatter to use for converting between json and `Date` values.
  /// - Returns: A parser for converting between json and `Date` values, using a `DateFormatter`.
  public static func jsonParser(formatter: DateFormatter) -> JSONString<DateParser> {
    JSONString { self.parser(formatter: formatter) }
  }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Date {
  /// A parser that can convert between `String` and `Date` values, using an given `Date.ISO8601FormatStyle`
  /// object.
  ///
  /// - Parameter style: The format style to use for converting between strings and `Date` values.
  /// - Returns: A parser for converting between strings and `Date` values, using a `Date.ISO8601FormatStyle`.
  public static func parser(style: Date.ISO8601FormatStyle) -> DateParser {
    .init(parseDate: { try? style.parse($0) }, formatDate: style.format(_:))
  }

  /// A parser that can convert between `String` and `Date` values, using an given `Date.FormatStyle`
  /// object.
  ///
  /// - Parameter style: The format style to use for converting between strings and `Date` values.
  /// - Returns: A parser for converting between strings and `Date` values, using a `Date.FormatStyle`.
  public static func parser(style: Date.FormatStyle) -> DateParser {
    .init(parseDate: { try? style.parse($0) }, formatDate: style.format(_:))
  }

  /// A parser that can convert between `JSONValue` values and `Date` values, using an given `Date.ISO8601FormatStyle`
  /// object.
  ///
  /// - Parameter style: The format style to use for converting between json and `Date` values.
  /// - Returns: A parser for converting between json and `Date` values, using a `Date.ISO8601FormatStyle`.
  public static func jsonParser(style: Date.ISO8601FormatStyle) -> JSONString<DateParser> {
    JSONString { self.parser(style: style) }
  }

  /// A parser that can convert between `JSONValue` values and `Date` values, using an given `Date.FormatStyle`
  /// object.
  ///
  /// - Parameter style: The format style to use for converting between json and `Date` values.
  /// - Returns: A parser for converting between json and `Date` values, using a `Date.FormatStyle`.
  public static func jsonParser(style: Date.FormatStyle) -> JSONString<DateParser> {
    JSONString { self.parser(style: style) }
  }
}

/// A parser for parsing `Date` values.
public struct DateParser: ParserPrinter {
  struct ParsingFailure: Error, CustomDebugStringConvertible {
    let message: String
    var debugDescription: String { message }
  }

  @usableFromInline let parseDate: (String) -> Date?
  @usableFromInline let formatDate: (Date) -> String

  public func parse(_ input: inout Substring) throws -> Date {
    guard let date = parseDate(String(input)) else {
      throw ParsingFailure(
        message: "Expected a date formatted such as \(formatDate(Date()))."
      )
    }
    input = ""
    return date
  }

  public func print(_ output: Date, into input: inout Substring) {
    input = Substring(formatDate(output))
  }
}

// MARK: - DateFromSecondsSince1970 conversion

extension Conversions {
  public struct DateFromSecondsSince1970: Conversion {
    public func apply(_ input: TimeInterval) -> Date {
      Date(timeIntervalSince1970: input)
    }
    public func unapply(_ output: Date) throws -> TimeInterval {
      output.timeIntervalSince1970
    }
  }
}

extension Conversion where Self == Conversions.DateFromSecondsSince1970 {
  /// A conversion between `TimeInterval` and `Date`, interpreting the `TimeInterval` value as
  /// number of seconds since 1970.
  public static var dateFromSecondsSince1970: Self {
    .init()
  }
}
