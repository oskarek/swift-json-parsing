import Foundation
import Parsing

extension Decodable {
  /// A parser that can parse json values into values of this type, using its `Decodable`
  /// conformance. If this type also conforms to `Encodable`, it can also be used to
  /// print values back into json.
  ///
  /// For example:
  ///
  /// ```
  /// struct Person: Decodable {
  ///   let name: String
  ///   let age: Int
  /// }
  ///
  /// let json = JSONValue.object([
  ///   "name": .string("Bob"),
  ///   "age": .integer(30),
  /// ])
  ///
  /// let person = try Person.jsonParser().parse(json)
  /// assert(person == Person(name: "Bob", age: 30))
  /// ```
  ///
  /// - Parameter decoder: The `JSONDecoder` to use for parsing.
  /// - Returns: A parser for parsing json values into this `Decodable` type.
  @_disfavoredOverload
  @inlinable
  public static func jsonParser(decoder: JSONDecoder = .init()) -> DecodableJSONParser<Self> {
    .init(decoder: decoder)
  }
}
extension Decodable where Self: Encodable {
  /// A parser that can parse json values into values of this type, using its `Decodable`
  /// conformance, as well as print values back into json using the `Encodable` conformance.
  ///
  /// For example:
  ///
  /// ```
  /// struct Person: Codable {
  ///   let name: String
  ///   let age: Int
  /// }
  ///
  /// let json = JSONValue.object([
  ///   "name": .string("Bob"),
  ///   "age": .integer(30),
  /// ])
  ///
  /// let person = try Person.jsonParser().parse(json)
  /// assert(person == Person(name: "Bob", age: 30))
  ///
  /// let printedJson = try try Person.jsonParser().print(person)
  /// assert(printedJson == json)
  /// ```
  ///
  /// - Parameters:
  ///   - decoder: The `JSONDecoder` to use for parsing.
  ///   - encoder: The `JSONEncoder` to use for printing.
  /// - Returns: A parser for parsing/printing json values to/from this `Decodable` type.
  @_disfavoredOverload
  @inlinable
  public static func jsonParser(
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init()
  ) -> DecodableJSONParser<Self> {
    .init(decoder: decoder, encoder: encoder)
  }
}

public struct DecodableJSONParser<Output: Decodable>: Parser {
  public let decoder: JSONDecoder
  public let encoder: JSONEncoder

  /// A parser that can parse `Decodable` values from json values. You should usually
  /// not interact directly with this type, but instead use the static func `jsonParser(decoder:encoder:)`,
  /// that's available on all types that conform to `Decodable`, to construct an instance.
  ///
  /// - Parameter decoder: The `JSONDecoder` to use for parsing.
  @inlinable
  public init(decoder: JSONDecoder = .init()) {
    self.decoder = decoder
    self.encoder = JSONEncoder()
  }

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> Output {
    do {
      return try decoder.decode(Output.self, from: input.toJsonData())
    } catch let error as DecodingError {
      throw JSONParsingError.fromDecodingError(error)
    } catch {
      throw JSONParsingError.failure("Decoding error:\n\(error)")
    }
  }
}

extension DecodableJSONParser where Output: Encodable {
  /// A parser that can parse `Decodable` values from json values. You should usually
  /// not interact directly with this type, but instead use the static func `jsonParser(decoder:encoder:)`,
  /// that's available on all types that conform to `Decodable`, to construct an instance.
  ///
  /// - Parameters:
  ///   - decoder: The `JSONDecoder` to use for parsing.
  ///   - encoder: The `JSONEncoder` to use for printing.
  @inlinable
  public init(decoder: JSONDecoder = .init(), encoder: JSONEncoder = .init()) {
    self.decoder = decoder
    self.encoder = encoder
  }
}

extension DecodableJSONParser: ParserPrinter where Output: Encodable {
  @inlinable
  public func print(_ output: Output, into input: inout JSONValue) throws {
    do {
      input = try .init(encoder.encode(output))
    } catch let error as EncodingError {
      throw JSONPrintingError.fromEncodingError(error)
    } catch {
      throw JSONPrintingError.failure("Encoding error:\n\(error)")
    }
  }
}
