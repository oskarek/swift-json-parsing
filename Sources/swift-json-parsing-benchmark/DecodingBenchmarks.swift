import Benchmark
import Foundation
import JSONParsing

let jsonDecodingBench = BenchmarkSuite(name: "Decoding") { suite in
  let jsonPath = Bundle.module.url(forResource: "sample_json", withExtension: "json")!
  let jsonData = try! Data(contentsOf: jsonPath)

  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  suite.benchmark("JSONDecoder (Codable)") {
    _ = try decoder.decode([Person].self, from: jsonData)
  }

  suite.benchmark("JSONParser") {
    _ = try JSONArray { Person.jsonParser }.decode(jsonData)
  }

  suite.benchmark("JSONParser (mixed with Codable)") {
    _ = try JSONArray { Person.jsonParserCombinedWithCodable }.decode(jsonData)
  }

  let jsonValue = try! JSONValue(jsonData)
  suite.benchmark("JSONParser (from JSONValue)") {
    _ = try JSONArray { Person.jsonParser }.parse(jsonValue)
  }
}
