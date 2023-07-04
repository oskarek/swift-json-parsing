import Foundation
import Parsing

extension Parser where Input == JSONValue {
  /// Use this parser to decode the json data into an output value.
  ///
  /// The decoding is done in two steps. First the json data is turned into a `JSONValue`,
  /// by using its initializer that takes json data. Then this parser is applied to that `JSONValue`.
  ///
  /// - Parameters:
  ///   - jsonData: The json data to decode.
  /// - Returns: A value decoded from the json data.
  public func decode(_ jsonData: Data) throws -> Output {
    let jsonValue = try JSONValue(jsonData)
    return try parse(jsonValue)
  }

  /// Use this parser to decode the json data into an output value.
  ///
  /// The decoding is done in two steps. First the json data is turned into a `JSONValue`,
  /// by using its initializer that takes json data. Then this parser is applied to that `JSONValue`.
  ///
  /// - Parameters:
  ///   - jsonData: The json data to decode.
  ///   - allowJSON5: If `true`, the json data is allowed to be in json5 format.
  /// - Returns: A value decoded from the json data.
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public func decode(_ jsonData: Data, allowJSON5: Bool) throws -> Output {
    let jsonValue = try JSONValue(jsonData, allowJSON5: allowJSON5)
    return try parse(jsonValue)
  }
}

extension ParserPrinter where Input == JSONValue {
  /// Use this parser to encode the value into json data.
  ///
  /// The encoding is done in two steps. First, the value is turned into a `JSONValue` representation,
  /// which is then further encoded into json data.
  ///
  /// - Parameter value: The value to encode into json data.
  /// - Returns: The encoded json data.
  public func encode(_ value: Output) throws -> Data {
    let jsonValue = try self.print(value)
    return try jsonValue.toJsonData()
  }
}

extension ParserPrinter where Input == JSONValue {
  /// Use this parser to turn the value into pretty printed json value.
  ///
  /// - Parameters:
  ///   - value: The value to be pretty printed as json.
  ///   - maxDepth: The maximum number of nesting levels to display.
  ///   - maxSubValueCount: The maximum number of sub values to display in arrays and objects.
  ///   - maxStringLength: The maximum number of characters to display in all strings.
  ///   - indentationString: The string to use for indentation. The default is two spaces.
  /// - Returns: A visual representation of the json value.
  public func prettyPrint(
    _ value: Output,
    maxDepth: Int? = nil,
    maxSubValueCount: Int? = nil,
    maxStringLength: Int? = nil,
    indentationString: String = "  "
  ) throws -> String {
    try self.print(value).prettyPrinted(
      maxDepth: maxDepth,
      maxSubValueCount: maxSubValueCount,
      maxStringLength: maxStringLength,
      indentationString: indentationString
    )
  }
}
