import Foundation

extension JSONPrintingError {
  @usableFromInline
  static func fromEncodingError(_ encodingError: EncodingError) -> Self {
    guard let context = encodingError.context else {
      return .failure(
        "(EncodingError) - \(encodingError.errorDescription ?? "Unknown error.")"
      )
    }
    let leafError = Self.failure("(EncodingError) - \(context.debugDescription)")
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

private extension EncodingError {
  var context: Context? {
    switch self {
    case let .invalidValue(_, context):
      return context
    @unknown default:
      return nil
    }
  }
}
