import Foundation

extension JSONValue: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() { self = .null; return }
    let value: JSONValue? = [
      { try .boolean(container.decode(Bool.self)) },
      { try .integer(container.decode(Int.self)) },
      { try .float(container.decode(Double.self)) },
      { try .string(container.decode(String.self)) },
      { try .array(container.decode([JSONValue].self)) },
      { try .object(container.decode([String: JSONValue].self)) },
    ].firstNonThrowing()
    guard let value else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Failed to decode a JSONValue"
      )
    }
    self = value
  }
}

extension JSONValue: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .array(list): try container.encode(list)
    case let .boolean(bool): try container.encode(bool)
    case .null: try container.encodeNil()
    case let .integer(integer): try container.encode(integer)
    case let .float(double): try container.encode(double)
    case let .object(dictionary): try container.encode(dictionary)
    case let .string(string): try container.encode(string)
    }
  }
}

private extension Sequence {
  /// Evaluate all the closures in the array, in order, and return the first one that returns a value without throwing.
  func firstNonThrowing<V>() -> V? where Element == () throws -> V {
    for f in self {
      if let v = try? f() { return v }
    }
    return nil
  }
}
