import Foundation

extension JSONValue {
  struct SerializationError: Error, CustomDebugStringConvertible {
    let message: String
    var debugDescription: String { message }
  }

  /// Try to initialize a `JSONValue` from a json data object.
  /// - Parameters:
  ///   - jsonData: The json data object to convert to a `JSONValue`.
  ///   - allowJSON5: If true, the json data object is allowed to be in json5 format.
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public init(_ jsonData: Data, allowJSON5: Bool) throws {
    try self.init(jsonData, extraOptions: allowJSON5 ? .json5Allowed : [])
  }

  /// Try to initialize a `JSONValue` from a json data object.
  /// - Parameters:
  ///   - jsonData: The json data object to convert to a `JSONValue`.
  public init(_ jsonData: Data) throws {
    try self.init(jsonData, extraOptions: [])
  }

  private init(_ jsonData: Data, extraOptions: JSONSerialization.ReadingOptions) throws {
    do {
      let options = extraOptions.union(.fragmentsAllowed)
      try self.init(JSONSerialization.jsonObject(with: jsonData, options: options))
    } catch let error as NSError {
      throw SerializationError(
        message: error.userInfo["NSDebugDescription"] as? String ?? error.debugDescription
      )
    }
  }

  private init(_ json: Any) throws {
    switch json {
    case is NSNull:
      self = .null
    case let num as NSNumber:
      if CFGetTypeID(num) == CFBooleanGetTypeID() {
        self = .boolean(num.boolValue)
      } else if CFNumberIsFloatType(num) {
        self = .float(num.doubleValue)
      } else {
        if let int = Int(exactly: num) {
          self = .integer(int)
        } else {
          self = .float(num.doubleValue)
        }
      }
    case let str as String:
      self = .string(str)
    case let array as [Any]:
      self = try .array(array.map(Self.init))
    case let dict as [String: Any]:
      self = try .object(dict.mapValues(Self.init))
    default:
      throw SerializationError(message: "Unknown format of json: \(json)")
    }
  }
}

extension JSONValue {
  /// Convert the `JSONValue` to json data.
  public func toJsonData() throws -> Data {
    var bytes: [UInt8] = []
    try serialize(into: &bytes)
    return Data(bytes)
  }
}

private extension JSONValue {
  func serialize(into bytes: inout [UInt8]) throws {
    switch self {
    case .null:
      bytes.append(contentsOf: [110, 117, 108, 108] /* "null".utf8 */)
    case .boolean(false):
      bytes.append(contentsOf: [102, 97, 108, 115, 101] /* "false".utf8 */)
    case .boolean(true):
      bytes.append(contentsOf: [116, 114, 117, 101] /* "true".utf8 */)
    case let .integer(int):
      bytes.append(contentsOf: String(int).utf8)
    case let .float(double):
      if double.isNaN {
        throw SerializationError(
          message: "Can't serialize JSONValue containing a NaN number."
        )
      }
      if double.isInfinite {
        throw SerializationError(
          message: "Can't serialize JSONValue containing an infinite number."
        )
      }
      bytes.append(contentsOf: String(double).utf8)
    case let .string(string):
      try string.serialize(into: &bytes)
    case let .array(array):
      bytes.append(.init(ascii: "["))
      try array.forEach { jsonValue in
        try jsonValue.serialize(into: &bytes)
      } doInBetween: {
        bytes.append(.init(ascii: ","))
      }
      bytes.append(.init(ascii: "]"))
    case let .object(dict):
      bytes.append(.init(ascii: "{"))
      try dict.sorted(by: { $0.key < $1.key }).forEach { key, value in
        try key.serialize(into: &bytes)
        bytes.append(.init(ascii: ":"))
        try value.serialize(into: &bytes)
      } doInBetween: {
        bytes.append(.init(ascii: ","))
      }
      bytes.append(.init(ascii: "}"))
    }
  }
}

private extension String {
  func serialize(into bytes: inout [UInt8]) throws {
    let data = try JSONSerialization.data(
      withJSONObject: self,
      options: [.fragmentsAllowed, .withoutEscapingSlashes]
    )
    bytes.append(contentsOf: Array(data))
  }
}

private extension Sequence {
  func forEach(_ perform: (Element) throws -> Void, doInBetween: () throws -> Void) rethrows {
    var it = makeIterator()
    if let first = it.next() { try perform(first) }
    while let item = it.next() {
      try doInBetween()
      try perform(item)
    }
  }
}
