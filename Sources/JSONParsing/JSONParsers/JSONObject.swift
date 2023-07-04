import Foundation
import Parsing

/// A parser that tries to parse a json value as an object, and turn it into a Swift `Dictionary` value.
///
/// For example:
///
/// ```swift
/// let json: JSONValue = .object([
///   "key1": false,
///   "key2": true,
///   "key3": true,
/// ])
/// let parser = JSONObject {
///   Bool.jsonParser()
/// }
/// let dictionary = try parser.parse(json)   // [String: Bool]
/// assert(dictionary == ["key1": false, "key2": true, "key3": true])
/// ```
///
/// Since the wrapped `valueParser` in this example is a `ParserPrinter`, the `JSONObject` parser is also a `ParserPrinter`
/// and can be used to print dictionary values into json objects:
///
/// ```swift
/// let dictionary = ["a": true, "b": true, "c": false]
/// let json = try parser.print(dictionary)   // JSONValue
/// assert(json == .object(["a": true, "b": true, "c": false]))
/// ```
///
/// There are also initializers that take a parser for the _keys_, allowing you to parse into dictionaries with keys
/// of _any_ `Hashable` type, not just `String`. See the documentation of the individual initializers for more details.
public struct JSONObject<Key: Parser, Value: Parser>: Parser
where Key.Input == Substring, Key.Output: Hashable, Value.Input == JSONValue {
  /// The parser to apply to each key of the json object.
  public let keyParser: Key
  /// The parser to apply to each value of the json object.
  public let valueParser: Value
  /// The maximum number of fields in the object.
  public let maximum: Int?
  /// The minimum number of fields in the object.
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
    "key/value pair" + (minimum == 1 && [nil, minimum].contains(maximum) ? "" : "s")
  }

  /// Initialize a parser that tries to parse a json value as an object, and turn it into a Swift `Dictionary` value.
  ///
  /// You can provide an optional `range` to limit the number of key/value pair that are accepted,
  /// as well as indvidual parsers to be used for the _keys_ and the _values_ respectively.
  ///
  /// For example, image that you want to parse a json that looks something like this:
  ///
  /// ```
  /// {
  ///   "key_1": "Steve Jobs",
  ///   "key_2": "Tim Cook",
  ///   ...
  /// }
  /// ```
  ///
  /// and you want to parse this into a `[Int: String]` dictionary, where the keys are the integer suffixes from the json keys.
  /// Also, you require that the object contains somewhere between 1 and 5 key/value pairs.
  ///
  /// You can achieve this with the following:
  ///
  /// ```swift
  /// let parser = JSONObject(1...5) {
  ///   String.jsonParser()
  /// } keys: {
  ///   "key_"
  ///   Int.parser()
  /// }
  /// ```
  ///
  /// The first closure is for the values, and here you say that you want to simply parse them as raw strings.
  /// Then with the `keys` closure, it is specified that the keys should all start with the `"key_"` prefix and than have an
  /// integer number, which is extracted to form the keys for the resulting dictionary.
  ///
  /// This parser is used like this:
  ///
  /// ```swift
  /// let json: JSONValue = .object([
  ///   "key_1": "Steve Jobs",
  ///   "key_2": "Tim Cook",
  ///   ...
  /// ])
  /// let dictionary = try parser.parse(json)   // [Int: String]
  /// assert(dictionary == [1: "Steve Jobs", 2: "Tim Cook", ...])
  /// ```
  ///
  /// - Parameters:
  ///   - range: A range that decides the minimum and maximum number of key/value pairs. Any length outside this range will cause parsing to fail.
  ///   - values: The parser to run on each value in the json object.
  ///   - keys: The parser to run on each key in the json object.
  @inlinable
  public init<R: CountingRange>(
    _ range: R = 0...,
    @ParserBuilder<JSONValue> values: @escaping () -> Value,
    @ParserBuilder<Substring> keys: @escaping () -> Key
  ) {
    self.keyParser = keys()
    self.valueParser = values()
    self.maximum = range.maximum
    self.minimum = range.minimum
  }

  @inlinable
  public func parse(_ input: inout JSONValue) throws -> [Key.Output: Value.Output] {
    guard case let .object(dict) = input else {
      throw JSONParsingError.typeMismatch(expected: "an object", got: input)
    }

    if isOutOfRange(dict.count) {
      throw JSONParsingError.failure(
        "Expected \(rangeString) \(rangeSuffix) in object, but found \(dict.count)."
      )
    }

    var outputDict: [Key.Output: Value.Output] = [:]
    for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
      let outputKey: Key.Output
      do {
        outputKey = try keyParser.parse(key)
      } catch {
        throw JSONParsingError.failure(
          """
          Failed to parse key \(key):
          \(error)
          """
        )
      }
      do {
        outputDict[outputKey] = try valueParser.parse(value)
      } catch {
        throw JSONParsingError.failureInObject(atKey: key, error)
      }
    }

    input = .empty
    return outputDict
  }
}

extension JSONObject: ParserPrinter where Key: ParserPrinter, Value: ParserPrinter {
  @inlinable
  public func print(_ output: [Key.Output: Value.Output], into input: inout JSONValue) throws {
    guard input == .empty else { throw JSONPrintingError.expectedEmpty("JSONObject", got: input) }

    if isOutOfRange(output.count) {
      throw JSONParsingError.failure(
        "An JSONObject parser requiring \(rangeString) \(rangeSuffix) was given \(output.count) to print."
      )
    }

    var inputDict: [String: JSONValue] = [:]
    for (key, value) in output {
      let printedKey: String
      do {
        printedKey = try String(keyParser.print(key))
      } catch {
        throw JSONPrintingError.failure(
          """
          Printing failure for key \(key):
          \(error)
          """
        )
      }
      do {
        inputDict[printedKey] = try valueParser.print(value)
      } catch {
        throw JSONPrintingError.failureInObject(atKey: printedKey, error)
      }
    }
    input = .object(inputDict)
  }
}

extension JSONObject {
  /// Initialize a parser that tries to parse a json value as an object, and turn it into a Swift `Dictionary` value,
  /// using a custom `Conversion` to parse the keys.
  ///
  /// For example:
  ///
  /// ```swift
  /// struct UserID: RawRepresentable, Hashable {
  ///   var rawValue: String
  /// }
  /// let json: JSONValue = .object([
  ///   "abc": "user 1",
  ///   "def": "user 2",
  /// ])
  /// let parser = JSONObject(keys: .representing(UserID.self)) {
  ///   String.jsonParser()
  /// }
  /// let dictionary = try parser.parse(json)   // [UserID: String]
  /// assert(dictionary == [UserID(rawValue: "abc"): "user 1", UserID(rawValue: "def"): "user 2"])
  /// ```
  ///
  /// - Parameters:
  ///   - range: A range that decides the minimum and maximum number of key/value pairs. Any length outside this range will cause parsing to fail.
  ///   - keyConversion: A conversion to apply to the keys.
  ///   - values: The parser to run on each value in the json object.
  @inlinable
  public init<R: CountingRange, C: Conversion<String, Key.Output>>(
    _ range: R = 0...,
    keys keyConversion: C,
    @ParserBuilder<JSONValue> values: @escaping () -> Value
  )
  where Key ==
    Parsers.MapConversion<
      Parsers.ReplaceError<Rest<Substring>>,
      Conversions.Map<Conversions.SubstringToString, C>
    >
  {
    self.init(range, values: values) {
      Rest().replaceError(with: "").map(.string.map(keyConversion))
    }
  }

  /// Initialize a parser that tries to parse a json value as an object, and turn it into a Swift `Dictionary` value.
  ///
  /// For example:
  ///
  /// ```swift
  /// let json: JSONValue = .object([
  ///   "key1": false,
  ///   "key2": true,
  ///   "key3": true,
  /// ])
  /// let parser = JSONObject {
  ///   Bool.jsonParser()
  /// }
  /// let dictionary = try parser.parse(json)   // [String: Bool]
  /// assert(dictionary == ["key1": false, "key2": true, "key3": true])
  /// ```
  ///
  /// - Parameters:
  ///   - range: A range that decides the minimum and maximum number of key/value pairs. Any length outside this range will cause parsing to fail.
  ///   - values: The parser to run on each value in the json object.
  @inlinable
  public init<R: CountingRange>(
    _ range: R = 0...,
    @ParserBuilder<JSONValue> values: @escaping () -> Value
  )
  where Key ==
    Parsers.MapConversion<
      Parsers.ReplaceError<Rest<Substring>>,
      Conversions.SubstringToString
    >
  {
    self.init(range, values: values) { Rest().replaceError(with: "").map(.string) }
  }
}
