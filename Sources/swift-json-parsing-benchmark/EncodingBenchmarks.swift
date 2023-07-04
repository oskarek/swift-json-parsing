import Benchmark
import Foundation
import JSONParsing

let jsonEncodingBench = BenchmarkSuite(name: "Encoding") { suite in
  let persons = Array(repeating: Person.bob, count: 100)

  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase

  suite.benchmark("JSONEncoder (Codable)") {
    _ = try encoder.encode(persons)
  }

  suite.benchmark("JSONParser") {
    _ = try JSONArray { Person.jsonParser }.encode(persons)
  }

  suite.benchmark("JSONParser (mixed with Codable)") {
    _ = try JSONArray { Person.jsonParserCombinedWithCodable }.encode(persons)
  }

  suite.benchmark("JSONParser (to JSONValue)") {
    _ = try JSONArray { Person.jsonParser }.print(persons)
  }
}
