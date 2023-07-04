import Foundation
import Parsing

extension UUID {
  /// A parser that can convert between `JSONValue` values and `UUID` values.
  /// - Returns: A parser for converting between json and `UUID` values.
  public static func jsonParser() -> JSONString<From<Conversions.SubstringToUTF8View, Substring.UTF8View, Parsers.UUIDParser<Substring.UTF8View>>> {
    JSONString { UUID.parser() }
  }
}
