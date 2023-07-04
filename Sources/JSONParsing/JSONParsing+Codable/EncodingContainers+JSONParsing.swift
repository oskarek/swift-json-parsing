import Foundation
import Parsing

extension KeyedEncodingContainer {
  /// Encodes the given value for the given key, using the given json parser.
  /// - Parameters:
  ///   - value: The value to encode.
  ///   - key: The key to associate the value with.
  ///   - valueParser: The json parser to use for encoding the value.
  public mutating func encode<Output>(
    _ value: Output,
    forKey key: Key,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParserPrinter<Output>
  ) throws {
    let json = try valueParser().print(value)
    try encode(json, forKey: key)
  }

  /// Encodes the given value for the given key if it is not `nil`, using the given json parser.
  /// - Parameters:
  ///   - value: The value to encode.
  ///   - key: The key to associate the value with.
  ///   - valueParser: The json parser to use for encoding the value.
  public mutating func encodeIfPresent<Output>(
    _ value: Output?,
    forKey key: Key,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParserPrinter<Output>
  ) throws {
    guard let value else { return }
    try encode(value, forKey: key) { valueParser() }
  }
}

extension UnkeyedEncodingContainer {
  /// Encodes the given value, using the given json parser.
  /// - Parameters:
  ///   - value: The value to encode.
  ///   - valueParser: The json parser to use for encoding the value.
  public mutating func encode<Output>(
    _ value: Output,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParserPrinter<Output>
  ) throws {
    let json = try valueParser().print(value)
    try encode(json)
  }
}

extension SingleValueEncodingContainer {
  /// Encodes a single value of the given type, using the given json parser.
  /// - Parameters:
  ///   - value: The value to encode.
  ///   - valueParser: The json parser to use for encoding the value.
  public mutating func encode<Output>(
    _ value: Output,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParserPrinter<Output>
  ) throws {
    let json = try valueParser().print(value)
    try encode(json)
  }
}
