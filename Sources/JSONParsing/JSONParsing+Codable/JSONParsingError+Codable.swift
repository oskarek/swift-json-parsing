import Foundation

enum CodingPathComponent {
  case objectKey(String)
  case arrayIndex(Int)
}

extension CodingKey {
  var asPathComponent: CodingPathComponent {
    if let index = (try? Parse { "Index "; Int.parser() }.parse(stringValue)) {
      return .arrayIndex(index)
    } else {
      return .objectKey(stringValue)
    }
  }
}

extension JSONParsingError {
  @usableFromInline
  static func fromDecodingError(_ decodingError: DecodingError) -> Self {
    guard let context = decodingError.context else {
      return .failure(
        "(DecodingError) - \(decodingError.errorDescription ?? "Unknown error.")"
      )
    }
    let leafError = Self.failure("(DecodingError) - \(context.debugDescription)")
    let path = context.codingPath.map(\.asPathComponent)
    return path.reversed().reduce(leafError) { error, pathComponent in
      switch pathComponent {
      case let .objectKey(key):
        return .failureInObject(atKey: key, error)
      case let .arrayIndex(index):
        return .failureInArray(atIndex: index, error)
      }
    }
  }
}

private extension DecodingError {
  var context: Context? {
    switch self {
    case let .typeMismatch(_, context):
      return context
    case let .valueNotFound(_, context):
      return context
    case let .keyNotFound(_, context):
      return context
    case let .dataCorrupted(context):
      return context
    @unknown default:
      return nil
    }
  }
}
