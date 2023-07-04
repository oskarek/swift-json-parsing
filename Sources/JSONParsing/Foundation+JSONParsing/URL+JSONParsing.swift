import Foundation
import Parsing

extension URL {
  /// A parser that can convert between `String` and `URL` values.
  /// - Returns: A parser for converting between strings and `URL` values.
  public static func parser() -> URLParser {
    .init()
  }

  /// A parser that can convert between `JSONValue` values and `Date` values.
  /// - Returns: A parser for converting between json and `URL` values.
  public static func jsonParser() -> JSONString<URLParser> {
    JSONString { parser() }
  }
}

/// A parser for converting between `JSONValue` values and `URL` values.
public struct URLParser: ParserPrinter {
  struct ParsingFailure: Error, CustomDebugStringConvertible {
    let message: String
    var debugDescription: String { message }
  }

  public func parse(_ input: inout Substring) throws -> URL {
    guard let url = URL(string: String(input)) else {
      throw ParsingFailure(message: "Expected a url.")
    }
    input = ""
    return url
  }

  public func print(_ output: URL, into input: inout Substring) {
    input = Substring(output.absoluteString)
  }
}
