import Foundation

public enum JSONPrintingError: Error {
  case failure(String)
  case failureInObject(atKey: String, Error)
  case failureInArray(atIndex: Int, Error)
}

extension JSONPrintingError {
  public static func expectedEmpty(_ parser: String, got actualValue: JSONValue) -> Self {
    .typeMismatch(parser, expected: "an empty JSON object", got: actualValue)
  }

  public static func typeMismatch(_ parser: String, expected: String, got actualValue: JSONValue) -> Self {
    let prefix = "AEIOU".contains(where: { parser.first == $0 }) ? "An" : "A"
    return .failure(
      """
      \(prefix) \(parser) parser can only print to \(expected) but attempted to print to:
      \(actualValue.prettyPrinted(maxDepth: 2, maxSubValueCount: 3, maxStringLength: 60))
      """
    )
  }
}

extension JSONPrintingError: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .failure(message):
      return message
    case let .failureInObject(key, error):
      return "At \"\(key)\"" + error._debugDescription
    case let .failureInArray(index, error):
      return "At [index \(index)]" + error._debugDescription
    }
  }
}

private extension Error {
  var _debugDescription: String {
    switch self as? JSONPrintingError {
    case let .failureInObject(key, error):
      return "/\"\(key)\"" + error._debugDescription
    case let .failureInArray(index, error):
      return "/[index \(index)]" + error._debugDescription
    default:
      return ":\n\(self)"
    }
  }
}
