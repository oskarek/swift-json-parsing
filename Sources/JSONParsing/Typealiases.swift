import Foundation
import Parsing

public typealias JSONParser<T> = Parser<JSONValue, T>
public typealias JSONParserPrinter<T> = ParserPrinter<JSONValue, T>
