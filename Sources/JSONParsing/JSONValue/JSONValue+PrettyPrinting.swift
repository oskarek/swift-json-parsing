import Foundation

extension JSONValue {
  /// Creates a visual representation of the json value.
  ///
  /// Example:
  ///
  /// ```
  /// let json = JSONValue.object([
  ///   "name": .string("Lionel Messi"),
  ///   "yearOfBirth": .integer(1987),
  ///   "nationality": .string("Argentina"),
  ///   "clubsRepresented": .array([
  ///     .string("FC Barcelona"),
  ///     .string("PSG"),
  ///   ]),
  ///   "isStillActive": .boolean(true),
  /// ])
  ///
  /// print(json.prettyPrinted())
  /// // prints:
  /// // {
  /// //   "clubsRepresented": [ "FC Barcelona", "PSG" ],
  /// //   "isStillActive": true,
  /// //   "name": "Lionel Messi",
  /// //   "nationality": "Argentina",
  /// //   "yearOfBirth": 1987
  /// // }
  /// ```
  ///
  /// There are a few optional parameters that can be used to customize the output string representation.
  /// The `indentationString` parameter can be used to customize what string that is used as indentation,
  /// (the default is two spaces), and then the `maxDepth`, `maxSubValueCount`, and `maxStringLength`
  /// can be used to make the output more compact in various ways.
  ///
  /// Let's see how it looks:
  ///
  /// ```
  /// let json = JSONValue.object([
  ///   "a": .boolean(true),
  ///   "b": .string("a string that is longer\nthan 60 characters, that is divided\ninto multiple lines"),
  ///   "c": .object([
  ///     "1": .object([
  ///       "x": .boolean(false),
  ///       "y": .string("hi"),
  ///       "z": .integer(2),
  ///     ]),
  ///     "2": .string("a string that is longer than 60 characters, that contains no newline characters"),
  ///     "3": .array([
  ///       .integer(1),
  ///       .integer(2),
  ///       .integer(3),
  ///       .string("four"),
  ///     ]),
  ///     "4": .integer(3),
  ///   ]),
  ///   "d": .boolean(false),
  ///   "e": .float(15.0),
  /// ])
  ///
  /// print(
  ///   json.prettyPrinted(
  ///     maxDepth: 2,
  ///     maxSubValueCount: 3,
  ///     maxStringLength: 60,
  ///     indentationString: " "
  ///   )
  /// )
  /// // prints:
  /// // {
  /// //  "a": true,
  /// //  "b": """
  /// //   a string that is longer
  /// //   than 60 characte...(+39 more chars)
  /// //   """,
  /// //  "c": {
  /// //   "1": { ...(+3 more) },
  /// //   "2": "a string that is longer than 60 characte...(+39 more chars)",
  /// //   "3": [ 1, 2, 3, "four" ],
  /// //   ...(+1 more)
  /// //  },
  /// //  ...(+2 more)
  /// // }
  /// ```
  ///
  /// - Parameters:
  ///   - maxDepth: The maximum number of nesting levels to display.
  ///   - maxSubValueCount: The maximum number of sub values to display in arrays and objects.
  ///   - maxStringLength: The maximum number of characters to display in all strings.
  ///   - indentationString: The string to use for indentation. The default is two spaces.
  /// - Returns: A visual representation of the json value.
  public func prettyPrinted(
    maxDepth: Int? = nil,
    maxSubValueCount: Int? = nil,
    maxStringLength: Int? = nil,
    indentationString: String = "  "
  ) -> String {
    let prettyPrinter = PrettyPrinter(
      maxDepth: maxDepth,
      maxSubValueCount: maxSubValueCount,
      maxStringLength: maxStringLength,
      indentationString: indentationString
    )
    return prettyPrinter.prettyPrint(self)
  }
}

private extension JSONValue {
  struct PrettyPrinter {
    let maxDepth: Int?
    let maxSubValueCount: Int?
    let maxStringLength: Int?
    let indentationString: String

    private func indentLines(in str: String) -> String {
      indentationString + str.replacingOccurrences(of: "\n", with: "\n" + indentationString)
    }

    func prettyPrint(_ jsonValue: JSONValue, depth: Int = 0, isObjectValue: Bool = false) -> String {
      switch jsonValue {
      case .null:
        return "null"

      case let .boolean(bool):
        return "\(bool)"

      case let .integer(int):
        return "\(int)"

      case let .float(double):
        return "\(double)"

      case var .string(string):
        if let maxStringLength, string.count > maxStringLength {
          let removedChars = string.count - (maxStringLength - 20)
          string.removeLast(removedChars)
          string.append("...(+\(removedChars) more chars)")
        }
        if string.contains("\n") {
          let lines = "\(string)\n\"\"\""
          return "\"\"\"\n" + (isObjectValue ? indentLines(in: lines) : lines)
        } else {
          return "\"\(string)\""
        }

      case let .array(array):
        let printedElements = array.map { prettyPrint($0, depth: depth + 1) }
        return wrap(printedElements, in: ("[","]"), depth: depth)

      case let .object(dictionary):
        let printedValues = dictionary
          .sorted(by: { $0.key < $1.key })
          .map { "\"\($0)\": " + prettyPrint($1, depth: depth + 1, isObjectValue: true) }
        return wrap(printedValues, in: ("{","}"), depth: depth)
      }
    }

    private func wrap(_ subValues: [String], in brackets: (open: String, close: String), depth: Int) -> String {
      guard !subValues.isEmpty else { return "\(brackets.open)\(brackets.close)" }

      let startCount = subValues.count
      var subValues = subValues

      if let oneLiner = wrapOnOneLine(subValues, in: brackets) { return oneLiner }

      let reachedMaxDepth = maxDepth.map { depth >= $0 } ?? false
      let maxCount = reachedMaxDepth ? 0 : maxSubValueCount ?? subValues.count
      subValues = .init(subValues.prefix(maxCount))

      let countNotShown = startCount - subValues.count
      if countNotShown > 0 { subValues.append("...(+\(countNotShown) more)") }

      if let oneLiner = wrapOnOneLine(subValues, in: brackets) { return oneLiner }

      return [
        brackets.open,
        subValues.map(indentLines).joined(separator: ",\n"),
        brackets.close,
      ]
      .joined(separator: "\n")
    }

    private func wrapOnOneLine(_ subValues: [String], in brackets: (open: String, close: String)) -> String? {
      let oneLiner = "\(brackets.open) " + subValues.joined(separator: ", ") + " \(brackets.close)"
      return oneLiner.count < 30 && !oneLiner.contains("\n") ? oneLiner : nil
    }
  }
}
