import Foundation

public enum JSONParsingError: Error {
  case failure(String)
  case failureInObject(atKey: String, Error)
  case failureInArray(atIndex: Int, Error)
}

extension JSONParsingError {
  public static func typeMismatch(expected: String, got actualValue: JSONValue) -> Self {
    .failure(
      """
      Expected \(expected), but found:
      \(actualValue.prettyPrinted(maxDepth: 2, maxSubValueCount: 3, maxStringLength: 60))
      """
    )
  }
}

extension JSONParsingError: CustomDebugStringConvertible {
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
    switch self as? JSONParsingError {
    case let .failureInObject(key, error):
      return "/\"\(key)\"" + error._debugDescription
    case let .failureInArray(index, error):
      return "/[index \(index)]" + error._debugDescription
    default:
      return ":\n\(self)"
    }
  }
}
