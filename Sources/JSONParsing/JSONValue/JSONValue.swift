import Foundation

/// A typed representation of a JSON value.
public enum JSONValue: Equatable {
  case null
  case boolean(Bool)
  case integer(Int)
  case float(Double)
  case string(String)
  case array([JSONValue])
  case object([String: JSONValue])
}

extension JSONValue: _EmptyInitializable {
  /// Initialize an empty JSON object. Equivalent to creating a `JSONValue.object([:])`.
  public init() { self = .empty }
  /// An empty JSON object. Equivalent to `JSONValue.object([:])`.
  public static let empty: JSONValue = .object([:])
}

// MARK: ExpressibleBy conformances

extension JSONValue:
  ExpressibleByBooleanLiteral,
  ExpressibleByIntegerLiteral,
  ExpressibleByFloatLiteral,
  ExpressibleByStringLiteral,
  ExpressibleByArrayLiteral,
  ExpressibleByDictionaryLiteral
{
  public init(booleanLiteral value: Bool) { self = .boolean(value) }
  public init(integerLiteral value: Int) { self = .integer(value) }
  public init(floatLiteral value: Double) { self = .float(value) }
  public init(stringLiteral value: String) { self = .string(value) }
  public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
  public init(dictionaryLiteral elements: (String, JSONValue)...) {
    self = .object(.init(uniqueKeysWithValues: elements))
  }
}
