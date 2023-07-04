import Foundation
import Parsing

extension KeyedDecodingContainer {
  /// Decodes a value at the given key, with the given json parser.
  ///
  /// - Parameters:
  ///   - type: The type of value to decode.
  ///   - key: The key that the parsed value is associated with.
  ///   - valueParser: The json parser to apply to the json value at the given key.
  /// - Returns: A value of the requested type, if present for the given key
  ///   and parsable to that type.
  public func decode<Output>(
    _ type: Output.Type = Output.self,
    forKey key: Key,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParser<Output>
  ) throws -> Output {
    let json = try decode(JSONValue.self, forKey: key)
    return try valueParser().parse(json)
  }

  /// Decodes a value with the given json parser at the given key, if present.
  ///
  /// This method returns `nil` if the container does not have a value
  /// associated with `key`, or if the value is null. The difference between
  /// these states can be distinguished with a `contains(_:)` call.
  ///
  /// - Parameters:
  ///   - type: The type of value to decode.
  ///   - key: The key that the parsed value is associated with.
  ///   - valueParser: The json parser to apply to the json value at the given key, if present.
  /// - Returns: A decoded value of the requested type, or `nil` if the
  ///   `Decoder` does not have an entry associated with the given key, or if
  ///   the value is a null value.
  public func decodeIfPresent<Output>(
    _ type: Output.Type = Output.self,
    forKey key: Key,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParser<Output>
  ) throws -> Output? {
    guard let json = try decodeIfPresent(JSONValue.self, forKey: key) else { return nil }
    return try valueParser().parse(json)
  }
}

extension SingleValueDecodingContainer {
  /// Decodes a single value of the given type, using the given json parser.
  ///
  /// - Parameters:
  ///   - type: The type of value to decode.
  ///   - valueParser: The json parser to apply to the json value.
  /// - Returns: A value of the requested type.
  public func decode<Output>(
    _ type: Output.Type = Output.self,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParser<Output>
  ) throws -> Output {
    let json = try decode(JSONValue.self)
    return try valueParser().parse(json)
  }
}

extension UnkeyedDecodingContainer {
  /// Decodes a value of the given type, using the given json parser.
  ///
  /// - Parameters:
  ///   - type: The type of value to decode.
  ///   - valueParser: The json parser to apply to the json value.
  /// - Returns: A value of the requested type.
  public mutating func decode<Output>(
    _ type: Output.Type = Output.self,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParser<Output>
  ) throws -> Output {
    let json = try decode(JSONValue.self)
    return try valueParser().parse(json)
  }

  /// Decodes a value of the given type, if present, using the given json parser.
  ///
  /// This method returns `nil` if the container has no elements left to decode, or if the value is null.
  /// The difference between these states can be distinguished by checking `isAtEnd`.
  ///
  /// - Parameters:
  ///   - type: The type of value to decode.
  ///   - valueParser: The json parser to apply to the json value.
  /// - Returns: A decoded value of the requested type, or `nil` if the value is a null value,
  /// or if there are no more elements to decode.
  public mutating func decodeIfPresent<Output>(
    _ type: Output.Type = Output.self,
    @ParserBuilder<JSONValue> valueParser: () -> some JSONParser<Output>
  ) throws -> Output? {
    guard let json = try decodeIfPresent(JSONValue.self) else { return nil }
    return try valueParser().parse(json)
  }
}
