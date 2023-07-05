# JSONParsing

[![CI](https://github.com/oskarek/swift-json-parsing/actions/workflows/ci.yml/badge.svg)](https://github.com/oskarek/swift-json-parsing/actions/workflows/ci.yml)

A library for decoding and encoding json, built on top of @pointfreeco's [Parsing](https://github.com/pointfreeco/swift-parsing) library.

* [Introduction](#introduction)
* [Quick start](#quick-start)
* [Motivation - why not use Codable?](#motivation---why-not-use-codable)
* [The `JSONValue` type](#the-jsonvalue-type)
* [The JSON parsers](#the-json-parsers)
    * [Null](#null)
    * [JSONBoolean](#jsonboolean)
    * [JSONNumber](#jsonnumber)
    * [JSONString](#jsonstring)
    * [JSONArray](#jsonarray)
    * [JSONObject](#jsonobject)
    * [Field](#field)
    * [OptionalField](#optionalfield)
* [Integration with Codable](#integration-with-codable)
* [Benchmarks](#benchmarks)
* [Installation](#installation)

---

## Introduction

As mentioned above, this library is built using the [Parsing](https://github.com/pointfreeco/swift-parsing) library, which is a library that provides a consistent story for writing _parsing_ code in Swift, that is, code that turns some _unstructured data_ into more _structured data_. You do that by constructing _parsers_ that are generic over both the (unstructured) _input_ and the (structued) _output_. What's really great is the fact the these parsers can be made _invertible_ (or bidirectional), meaning thay can also turn structured data _back_ into unstructed data, referred to as _printing_.

The *JSONParsing* library provides predefined parsers tuned specifically for when the _input is json_, giving you a convenient way of writing parsers capable of parsing (decoding) and printing (encoding) json. This style of dealing with json has a number of benefits compared to the *Codable* abstraction. More about that in the [Motivation](#motivation---why-not-use-codable) section.

## Quick start

Let's see what it looks like to decode and encode json data using this library. Imagine, for example, you have json describing a movie:

```swift
let json = """
{
  "title": "Interstellar",
  "release_year": 2014,
  "director": "Christopher Nolan",
  "stars": [
    "Matthew McConaughey",
    "Anne Hathaway",
    "Jessica Chastain"
  ],
  "poster_url": "https://www.themoviedb.org/t/p/w1280/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
  "added_to_favorites": true
}
""".data(using: .utf8)!
```

First, we define a corresponding `Movie` type:

```swift
struct Movie {
  let title: String
  let releaseYear: Int
  let director: String
  let stars: [String]
  let posterUrl: URL?
  let addedToFavorites: Bool
}
```

Then, we can create a _JSON parser_, to handle the decoding of the json into this new data type:

```swift
extension Movie {
  static var jsonParser: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      Field("title") { String.jsonParser() }
      Field("release_year") { Int.jsonParser() }
      Field("director") { String.jsonParser() }
      Field("stars") {
        JSONArray { String.jsonParser() }
      }
      OptionalField("poster_url") { URL.jsonParser() }
      Field("added_to_favorites") { Bool.jsonParser() }
    }
  }
}
```

Now, the `Movie.jsonParser` can be used to decode json data into `Movie` instances:

```swift
let decodedMovie = try Movie.jsonParser.decode(json)
print(decodedMovie)
// Movie(title: "Interstellar", releaseYear: 2014, director: "Christopher Nolan", stars: ["Matthew McConaughey", "Anne Hathaway", "Jessica Chastain"], posterUrl: Optional(https://www.themoviedb.org/t/p/w1280/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg), addedToFavorites: true)
```

But what's even cooler is that the very same parser, without any extra work, can also be used to _encode_ movie values into json:

```swift
let jokerMovie = Movie(
  title: "Joker",
  releaseYear: 2019,
  director: "Todd Phillips",
  stars: ["Joaquin Phoenix", "Robert De Niro"],
  posterUrl: URL(string: "https://www.themoviedb.org/t/p/w1280/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg")!,
  addedToFavorites: true
)

let jokerJson = try Movie.jsonParser.encode(jokerMovie)
print(String(data: jokerJson, encoding: .utf8)!)
// {"added_to_favorites":true,"director":"Todd Phillips","poster_url":"https://www.themoviedb.org/t/p/w1280/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg","release_year":2019,"stars":["Joaquin Phoenix","Robert De Niro"],"title":"Joker"}
```

More information about the building blocks for constructing the JSON parsers can be found under the [The JSON parsers](#the-json-parsers) section.

## Motivation - why not use Codable?

The default way to work with JSON in Swift is with Apple's own Codable framework. While it is a powerful abstraction, it does have some drawbacks and limitations. Let's explore some of them and see how the JSONParsing library addresses these issues.

### More than one JSON representation

One limitation of the Codable framework is that any given type can only have _one_ way of being represented as JSON. To work around this limitation, one common approach is to introduce wrapper types that wrap a value of the result type and have a custom Decodable implementation. Then, when decoding the type, you first decode to the wrapper type and then extract the underlying value. While this approach works, it's cumbersome to introduce a new type solely for handling JSON decoding. Moreover, the wrapper type needs to be explicitly used whenever you want to decode to the underlying type with that specific decoding strategy.

As an example, let's consider the following type representing an RGB color:

```swift
struct RGBColor {
  let red: Int
  let green: Int
  let blue: Int
}
```

What would be the corresponding json representation for this type? Would it be something like:

```json
{
  "red": 205,
  "green": 99,
  "blue": 138
}
```

Or perhaps:

```json
"205,99,138"
```

The truth is, both representations are reasonable (as well as many other possibilities), and it's possible that you might have one API endpoint returning RGB colors in the first format, and another in the second format. But when using Codable, you would have to choose one of the formats to be the one used for the `RGBColor` type. To handle both variants, you would have to define two separate types, something like `RGBColorWithObjectRepresentaion` and `RGBColorWithStringRepresentation`, and conform both of them to `Codable`, with the different decoding/encoding strategies.

Using the *JSONParsing* library, you can easily just create two separate parsers, one for each alternative:

```swift
extension RGBColor {
  static var jsonParserForObjectRepresentation: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      Field("red") { Int.jsonParser() }
      Field("green") { Int.jsonParser() }
      Field("blue") { Int.jsonParser() }
    }
  }

  static var jsonParserForStringRepresentation: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      JSONString {
        Int.parser()
        ","
        Int.parser()
        ","
        Int.parser()
      }
    }
  }
}
```

And now you can use whichever suits best in the given situation:

```swift
// in one place in the app

let colorJson1 = """
{
  "red": 205,
  "green": 99,
  "blue": 138
}
""".data(using: .utf8)!
// decode
let color1 = try RGBColor.jsonParserForObjectRepresentation.decode(colorJson1)
print(color1)
// RGBColor(red: 205, green: 99, blue: 138)

// encode
let newColorJson1 = try RGBColor.jsonParserForObjectRepresentation.encode(color1)
print(String(data: newColorJson1, encoding: .utf8)!)
// {"blue":138,"green":99,"red":205}

// in another place in the app

let colorJson2 = """
"55,190,25"
""".data(using: .utf8)!
// decode
let color2 = try RGBColor.jsonParserForStringRepresentation.decode(colorJson2)
print(color2)
// RGBColor(red: 205, green: 99, blue: 138)

// encode
let newColorJson2 = try RGBColor.jsonParserForStringRepresentation.encode(color2)
print(String(data: newColorJson2, encoding: .utf8)!)
// "55,190,25"
```

If you want, you could even define a configurable function, dealing with both variants in the same place:

```swift
extension RGBColor {
  static func jsonParser(useStringRepresentation: Bool = false) -> some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      if useStringRepresentation {
        JSONString {
          Int.parser()
          ","
          Int.parser()
          ","
          Int.parser()
        }
      } else {
        Field("red") { Int.jsonParser() }
        Field("green") { Int.jsonParser() }
        Field("blue") { Int.jsonParser() }
      }
    }
  }
}

try RGBColor.jsonParser(useStringRepresentation: false).decode(colorJson1)
// RGBColor(red: 205, green: 99, blue: 138)
try RGBColor.jsonParser(useStringRepresentation: true).decode(colorJson2)
// RGBColor(red: 205, green: 99, blue: 138)
```

#### The `Date` type

Perhaps the most common way to run into the limitation of a type only being able to have one single `Codable` conformance, is when dealing with the `Date` type. In fact, it's so common, that the Codable framework even provides a special way of managing how `Date` types are decoded/encoded, through the `dateDecodingStrategy`/`dateEncodingStrategy` properties available on `JSONDecoder` and `JSONEncoder`, respectively. While this does work, it's a little weird to have special handling for _one_ specific type, that looks nothing like how you deal with all the other types. Also, having the configuration on the Encoder/Decoder types, means you can't have more than one date format in the same json object.

With *JSONParsing* on the other hand, the `Date` type doesn't have to be handled as an exception. We saw above with the `RGBColor` type, that we can just create a parser that matches the required representation that is used in the JSON API. The library also extends the `Date` type with a static `jsonParser(formatter:)` method, which allows constructing a json parser that decodes/encodes dates according to a given `DateFormatter`:

```swift
let json = """
{
  "date1": "1998-11-20",
  "date2": "2021-06-01T13:09:09Z"
}
""".data(using: .utf8)!

struct MyType {
  let date1: Date
  let date2: Date
}

let basicFormatter = DateFormatter()
basicFormatter.dateFormat = "yyyy-MM-dd"

let isoFormatter = DateFormatter()
isoFormatter.dateFormat = "yyyy-MM-dd'T'HH':'mm':'ss'Z'"

extension MyType {
  static var jsonParser: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      Field("date1") { Date.jsonParser(formatter: basicFormatter) }
      Field("date2") { Date.jsonParser(formatter: isoFormatter) }
    }
  }
}

let parsedValue = try MyType.jsonParser.decode(json)
print(parsedValue)
// MyType(date1: 1998-11-20 00:00:00 +0000, date2: 2021-06-01 13:09:09 +0000)
let encodedJson = try MyType.jsonParser.encode(parsedValue)
print(String(data: encodedJson, encoding: .utf8)!)
// {"date1":"1998-11-20","date2":"2021-06-01T13:09:09Z"}
```

### Decoding and encoding logic out of sync

Codable has the really cool feature of being able to automatically sythesize the decoding and encoding implementations for Swift types, thanks to integration with the Swift compiler. Unfortunately, in practice, the automatically synthesized implementations will often not be correct for your usecase, because it assumes that your json data and your Swift data types _exactly_ match each other in structure. This will often not be the case, for various reasons. First, you might be dealing with JSON APIs that you don't own yourself and therefore might deliver data in a format that isn't ideal to your usecase. But even if you do own the API code, it might be used by multiple platforms, which means you can't tailor it specifically to work perfectly with your Swift code. Also, Swift has some features, such as enums, that simply _can't_ be expressed equivalently in json.

So in practice, when using Codable, you will often have to implement the decoding and encoding logic manually. And the problem in that situation, is that they have to be implemented _separately_. This means that, whenever the expected json format changes in any way, you have to remember to update both the `init(from:)` (decoding) and the `encode(to:)` (encoding) implementations accordingly.

With *JSONParsing* on the other hand, you can write a single json parser that can take care of both the decoding and the encoding (as was shown in the [Quick start](#quick-start) section). What this means is that you are guaranteed to always have the two transformations kept in sync as your json API evolves.

### Custom String parsing

Recall how we previously defined a json parser for the `RGBColor` type, where the json representation was a comma seperated string. It looked like this:

```swift
extension RGBColor {
  static var jsonParserForStringRepresentation: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      JSONString {
        Int.parser()
        ","
        Int.parser()
        ","
        Int.parser()
      }
    }
  }
}

let colorJson = """
"55,190,25"
""".data(using: .utf8)!
let color = try RGBColor.jsonParserForStringRepresentation.decode(colorJson)
print(color)
// RGBColor(red: 55, green: 190, blue: 25)
let newColorJson2 = try RGBColor.jsonParserForStringRepresentation.encode(color2)
print(String(data: newColorJson2, encoding: .utf8)!)
// "55,190,25"
```

In that example, it was used to highlight the fact that we can handle different json representations for the same type. However, it actually also shows off _another_ great thing about the library, which is how its integration with the *Parsing* library makes it very convenient to deal with types whose json representation requires custom String transformations.

Let's try to accomplish the same thing using Codable:

```swift
extension RGBColor: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let stringValue = container.decode(String.self)
    self.red = ???
    self.green = ???
    self.blue = ???
  }
}
```

How do we get the rgb components from the decoded String? The Codable abstraction doesn't really provide a general answer to this. We could of course use the *Parsing* library here if we want:

```swift
extension RGBColor: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let stringValue = try container.decode(String.self)
    self = try Parse(Self.init) {
      Int.parser()
      ","
      Int.parser()
      ","
      Int.parser()
    }
    .parse(stringValue)
  }
}
```

But it's not as seamlessly integrated into the rest of the code, as it was in the *JSONParsing* example, forcing us to manually call out to the `parse` method for instance. And also, again, this is only half of the equation, we still have to deal with the encoding, which has to be implemented on its own.

### JSON with alternative representations

Imagine that you are working with an api that delivers a list of ingredients in the following format:

```swift
let ingredientsJson = """
[
  {
    "name": "milk",
    "amount": {
      "value": 2,
      "unit": "dl"
    }
  },
  {
    "name": "salt",
    "amount": "a pinch"
  }
]
""".data(using: .utf8)!
```

As you can see, the `amount` can _either_ be expressed as a combination of a value and a unit, _or_ a string. In Swift, this is most naturally represented using an enum:

```swift
struct Ingredient {
  enum Amount {
    case exact(value: Int, unit: String)
    case freetext(String)
  }

  let name: String
  let amount: Amount
}
```

In this situation, we cannot get a suitable synthesized conformance to `Codable` for the `Amount` type, so we have no choice but to implement the methods ourselves. Let's do the `Decodable` conformance:

```swift
extension Ingredient.Amount: Decodable {
  enum CodingKeys: CodingKey {
    case unit
    case value
  }

  init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      self = .freetext(try container.decode(String.self))
    } catch {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let value = try container.decode(Int.self, forKey: .value)
      let unit = try container.decode(String.self, forKey: .unit)
      self = .exact(value: value, unit: unit)
    }
  }
}
```

For the `Ingredient` type we can just use the automatically synthesized conformance:

```swift
extension Ingredient: Decodable {}
```

Now we can use a `JSONDecoder` to decode the `ingredientsJson` into a list of `Ingredient`:

```swift
let ingredients = try JSONDecoder().decode([Ingredient].self, from: ingredientsJson)
print(ingredients)
// [Ingredient(name: "milk", amount: Ingredient.Amount.exact(value: 2, unit: "dl")), Ingredient(name: "salt", amount: Ingredient.Amount.freetext("a pinch"))]
```

So that works. We did have to create an explicit `CodingKeys` type as well as two separate `containers` for handling the two cases, which is a little bit of extra boilerplate, but it's not too bad. But there is actually a more fundamental problem here. To see that, let's modify the json input like this:

```diff
[
  ...
  {
    "name": "salt",
-   "amount": "a pinch"
+   "amount": 3
  }
]
""".data(using: .utf8)!
```

So the amount is now just a number, which is not allowed. When we try to decode the list, we get an error:

```swift
do {
  let ingredients = try JSONDecoder().decode([Ingredient].self, from: ingredientsJson)
} catch {
  print(error)
  // typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [_JSONKey(stringValue: "Index 1", intValue: 1), CodingKeys(stringValue: "amount", intValue: nil)], debugDescription: "Expected to decode Dictionary<String, Any> but found a number instead.", underlyingError: nil))
}
```

The error message isn't very easily readable, but hidden in there is the message: `"Expected to decode Dictionary<String, Any> but found a number instead."`. So judging by this error, it would seem like that the only valid type of value for the `amount` field is a nested json object. But we know that there is actually a second valid option, namely a string. But this information got lost when the error was created, because of our (arbitrary) choice in the `init(from:)` to _first_ try to decode it as a string, and then if that fails, try the other alternative. If we had written it in the other order, our error message would instead have said `"Expected to decode String but found a number instead."`. Either way, we are missing the fact that we have _multiple valid choices_.

So let's see how the JSONParsing library handles this kind of situation! Instead of conforming the types to `Decodable`, let's write _JSON parsers_ for them.

```swift
extension Ingredient.Amount {
  static var jsonParser: some JSONParserPrinter<Self> {
    OneOf {
      ParsePrint(.case(Self.exact)) {
        Field("value") { Int.jsonParser() }
        Field("unit") { String.jsonParser() }
      }

      ParsePrint(.case(Self.freetext)) {
        String.jsonParser()
      }
    }
  }
}

extension Ingredient {
  static var jsonParser: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      Field("name") { String.jsonParser() }
      Field("amount") { Amount.jsonParser }
    }
  }
}
```

We make use of the `OneOf` parser from the *Parsing* library, which will run a number of parsers until one succeeds, and if no one succeeds their errors are accumulated. Let's try decoding the same json as before, and see what is printed[^1]:

```swift
do {
  let ingredients = try JSONArray { Ingredient.jsonParser }.decode(ingredientsJson)
} catch {
  print(error)
  // At [index 1]/"amount":
  // error: multiple failures occurred
  //
  // error: Expected an object (containing the key "value"), but found:
  // 3
  //
  // Expected a string, but found:
  // 3
}
```

As you can see, _both_ possibilities are now mentioned in the printed error message. Also, as a bonus, the error message is _a lot_ easier to read.

This also serves as a glimpse at what printed errors look like when using this library. They always have basically the same layout as what you see above: a path describing where something went wrong, and then a more detailed description of _what_ went wrong. All in an easily readable format.

[^1]: At the time of writing, this is actually a slight lie. In this exact situation, the first line `At [index 1]/"amount":` would in fact be split across two lines reading `At [index 1]:` and `error: At "amount":` respectively. This is due to a current limitation preventing the error path to be printed in the ideal way, that will hopefully be fixed in the near future. In many other situations though, the error path will be printed in that nice compact format, so I still wanted to show that version.

### Decoding/encoding logic spread out

Another thing that I don't think is ideal with the Codable abstraction is that the decoding/encoding logic lives in two separate places. In part, it is implemented in the types when they conform to the two protocols, but then you can _also_ control some of the behavior via properties on the `JSONDecoder`/`JSONEncoder` instance that you use to perform the decoding/encoding. For instance, the `JSONDecoder` type has a `keyDecodingStrategy` property that can be used to control how keys in the json objects are pre-processed during decoding, and a `dateDecodingStrategy` that can be used to control how dates are decoded.

What this means is that a type's conformance to `Decodable`/`Encodable` _is not a complete description of how that type is converted to/from json_. To fully control how that happens, you _also_ have to be in control over which `JSONDecoder`/`JSONEncoder` instance that is used.

When using *JSONParsing*, on the other hand, any json parser that you create, _exactly_ determines how to transform a type to/from a json representation.

## The `JSONValue` type

So far we have glossed over a detail of the library, that isn't immediately necessary to know about to start using it, but is useful to know about to understand how things work under the hood. Everywhere when we have created json parsers, we have given it the type of either `some JSONParser<T>` or `some JSONParserPrinter<T>`, and then when using them to decode or encode json data, we have used the `decode(_:)` and `encode(_:)` methods, respectively.

As it turns out, `JSONParser<T>` and `JSONParserPrinter<T>` are just typealiases for `Parser<JSONValue, T>` and `ParserPrinter<JSONValue, T>`, respectively (`ParserPrinter` means it can both parse (decode) and print (encode), see [the documentation](https://pointfreeco.github.io/swift-parsing/main/documentation/parsing/gettingstarted) for the *Parsing* library for more details).

So we are actually defining parsers that take as input a type called `JSONValue`. This is a type exposed from this library, and just serves as a very basic typed representation of json, that looks like this:

```swift
public enum JSONValue: Equatable {
  case null
  case boolean(Bool)
  case integer(Int)
  case float(Double)
  case string(String)
  case array([JSONValue])
  case object([String: JSONValue])
}
```

So when we call the `decode(_:)` and `encode(_:)` methods on the parsers, the decoding and encoding happens in two steps: the json data is transformed to/from the `JSONValue` type, and the `JSONValue` type is in turn transformed to/from the result type using the `Parser.parse`/`ParserPrinter.print` methods.

The primary usecase for the `JSONValue` type is just to act as this middle layer, to simplify the implementations of the various json parsers that ship with the library. However, it can actually be useful on its own. For instance, you might have code like this today:

```swift
let json: [String: Any] = [
  "title": "hello",
  "more_info": ["a": 1, "b": 2, ...],
  ...
]
let jsonData = try JSONSerialization.data(withJSONObject: json)
var request = URLRequest(url: requestUrl)
request.httpMethod = "POST"
request.httpBody = jsonData
```

While that does work, the fact that the `json` has type `[String: Any]` means that it could actually be a dictionary that holds _any_ kind of data. In particular, it could hold data that isn't valid json data, and the compiler won't let you know. For instance, we could add a `Date` in the `title` field, and the compiler will be fine with it, but it will result in a runtime crash:

```swift
let json: [String: Any] = [
  "title": Date(),
  "more_info": ["a": 1, "b": 2, ...],
  ...
]
let jsonData = try JSONSerialization.data(withJSONObject: json)
// runtime crash: *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Invalid type in JSON write (__NSTaggedDate)'
```

By using the `JSONValue` type instead in this scenario, you can get a compile time guarantee that your json data is valid. And thanks to the fact that `JSONValue` conforms to a number of `ExpressibleBy...` protocols, it can actually be initialized with the _exact_ same syntax as before. So the previous example becomes:

```swift
let json: JSONValue = [
  "title": "hello",
  "more_info": ["a": 1, "b": 2, ...],
  ...
]
let jsonData = try json.toJsonData()
// ... the rest is the same
```

If we now try to replace `"hello"` with `Date()` as we did before, this time the compiler won't let us:

```swift
let json: [String: Any] = [
  "title": Date(), // compiler error: Cannot convert value of type 'Date' to expected dictionary value type 'JSONValue'
  "more_info": ["a": 1, "b": 2, ...],
  ...
]
```

## The JSON parsers

This library ships with a number of json parsers, that can be composed together to deal with more complex json structures. As mentioned in the previous section, they all take values of the custom type `JSONValue` as input, so when using the `parse`/`print` methods, they convert to/from that type.

When you want to use them to decode/encode json _data_ (which is likely to be the most common usecase) you just use the `decode`/`encode` methods defined on them instead, which does the converting to from data for you.

### Null

The `Null` parser is used for parsing the special json value `null`. You use it when you need to explicitly make sure that a value is null.

```swift
let nullJson: JSONValue = .null
let nonNullJson: JSONValue = 5.0

try Null().parse(nullJson)
// ()
try Null().parse(nonNullJson)
// throws:
// Expected a null value, but found:
// 5.0
```

When used as a printer (encoder), the `Null` parser prints `.null`:

```swift
try Null().print(()) // .null
```

### JSONBoolean

The `JSONBoolean` parser is used for parsing json booleans. It succeeds only when given either a `false` or `true` json value, and returns the corresponding `Bool` value.

```swift
let booleanJson: JSONValue = false
let nonBooleanJson: JSONValue = [
  "key1": 1,
  "key2": "hello"
]

try JSONBoolean().parse(booleanJson)
// false
try JSONBoolean().parse(nonBooleanJson)
// throws:
// Expected a boolean, but found:
// {
//   "key1": 1,
//   "key2": "hello"
// }
```

An alternative way of constructing a `JSONBoolean` parser, is via the static `jsonParser()` method on the `Bool` type:

```swift
try Bool.jsonParser().parse(booleanJson)
// false
```

The `JSONBoolean` parser can also be used for printing (encoding) back into json:

```swift
try Bool.jsonParser().print(true)
// .boolean(true)
```

### JSONNumber

The `JSONNumber` parser is used for parsing json numbers. Notable is the fact that the `JSONValue` type has a separation between _floating point_ numbers, and _integer_ numbers. When using it to parse to a floating point type, the parser takes an optional parameter called `allowInteger`, which controls whether it succeeds on integers as well as floating points. If not specified, that defaults to `true`.

```swift
let integerJson: JSONValue = 10 // or .integer(10)
let floatJson: JSONValue = 2.4 // or .float(2.4)
let nonNumberJson: JSONValue = "hello"

try JSONNumber<Int>().parse(integerJson)
// 10
try JSONNumber<Double>().parse(floatJson)
// 2.4
try JSONNumber<Int>().parse(floatJson)
// throws:
// Expected an integer number, but found:
// 2.4
try JSONNumber<Double>().parse(integerJson)
// 10.0
try JSONNumber<Double>(allowInteger: false).parse(integerJson)
// throws:
// Expected a floating point number, but found:
// 10
try JSONNumber<Double>().parse(nonNumberJson)
// throws:
// Expected a number, but found:
// "hello"
```

Alternatively, a `JSONNumber` parser can be constructed via the `jsonParser()` static methods defined on `BinaryInteger` and `BinaryFloatingPoint`:

```swift
try Int.jsonParser().parse(integerJson) // 10
try Int64.jsonParser().parse(integerJson) // 10
try Double.jsonParser().parse(floatJson) // 2.4
try CGFloat.jsonParser(allowInteger: false).parse(floatJson) // 2.4
```

Note: when decoding json _data_, using the `decode` method, a number in the json object is interpreted as a floating point if it has _any_ decimals (including just a `0`).

```swift
let json = """
{
  "a": 10,
  "b": 10.5,
  "c": 10.0
}
""".data(using: .utf8)!

try Field("a") { Int.jsonParser() }.decode(json)
// 10
try Field("b") { Int.jsonParser() }.decode(json)
// throws:
// At "b":
// Expected an integer number, but found:
// 10.5
try Field("c") { Int.jsonParser() }.decode(json)
// throws:
// At "c":
// Expected an integer number, but found:
// 10.0
try Field("b") { Double.jsonParser() }.decode(json)
// 10.5
try Field("c") { CGFloat.jsonParser() }.decode(json)
// 10.0
```

The `JSONNumber` parser can also be used for printing to json:

```swift
try Int.jsonParser().print(25) // .integer(25)
try Double.jsonParser().print(1.6) // .float(1.6)
```

### JSONString

The `JSONString` parser is used for parsing json strings. And as has been showed in previous sections, it can also be given a string parser, for performing custom parsing of the string value.

```swift
let stringJson: JSONValue = "120,200,43"
let nonStringJson: JSONValue = [1, 2, 3]

try JSONString().parse(stringJson)
// "120,200,43"
try JSONString().parse(nonStringJson)
// throws:
// Expected a string, but found:
// [ 1, 2, 3 ]
try JSONString {
  Int.parser()
  ","
  Int.parser()
  ","
  Int.parser()
}.parse(stringJson)
// (120, 200, 43)

let nonMatchingStringJson: JSONValue = "apple"

try JSONString {
  Int.parser()
  ","
  Int.parser()
  ","
  Int.parser()
}.parse(stringJson)
// throws:
// error: unexpected input
//  --> input:1:1
// 1 | apple
//   | ^ expected integer
```

There is also a version of the initializer that takes a string _conversion_. A conversion is a concept introduced in the *Parsing* library, and works like a two-way function. The library also exposes a number of predefined conversions, for example the `representing(_:)` conversion, that can be used to convert between `RawRepresentable` types, and their raw values. Using it with the `JSONString` parser looks like this:

```swift
enum Direction: String {
  case up, down, left, right
}
extension Direction {
  static let jsonParser = JSONString(.representing(Direction.self))
}
let json: JSONValue = "left"
let direction = Direction.jsonParser.parse(json)
print(direction) // Direction.left

try Direction.jsonParser.print(direction)
// .string("left")
```

When you don't need any custom parsing, and just want to parse a json string as it is, you can also choose to define the parser with the static `jsonParser()` method defined on the `String` type:

```swift
let json: JSONValue = "hello"
try String.jsonParser().parse(json)
// "hello"
```

The `JSONString` can be used as a printer, to print (decode) to json, as long as the underlying string parser given to it is a printer itself.

```swift
try JSONString {
  Int.parser()
  ","
  Int.parser()
  ","
  Int.parser()
}.print((120, 200, 43))
// .string("120,200,43")
```

### JSONArray

The `JSONArray` parser is used for parsing json arrays. You construct it by providing a parser that should be applied to each element of the array. As a bonus you can also, optionally, specify that the array must be of a certain size, by giving it a range or a single number. It looks like this to use it for parsing json:

```swift
let directionArrayJson: JSONValue = ["left", "left", "right", "up"]
let numberArrayJson: JSONValue = [1, 2, 3]
let nonArrayJson: JSONValue = 10.5

try JSONArray {
  Direction.jsonParser
}.parse(directionArrayJson)
// [Direction.left, Direction.left, Direction.right, Direction.up]

try JSONArray(1...3) {
  Direction.jsonParser
}.parse(directionArrayJson)
// throws:
// Expected 1-3 elements in array, but found 4.

try JSONArray(3) {
  Direction.jsonParser
}.parse(directionArrayJson)
// throws:
// Expected 3 elements in array, but found 4.

try JSONArray {
  Direction.jsonParser
}.parse(numberArrayJson)
// throws:
// At [index 0]:
// Expected a string, but found:
// 1

try JSONArray {
  Int.jsonParser()
}.parse(numberArrayJson)
// [1, 2, 3]

try JSONArray {
  Int.jsonParser()
}.parse(nonArrayJson)
// throws:
// Expected an array, but found:
// 10.5
```

And for printing (which is available whenever the element parser given to it has printing capabilities):

```swift
try JSONArray {
  Direction.jsonParser
}.print([Direction.right, .left, .down])
// .array(["right", "left", "down"])
```

### JSONObject

The `JSONObject` parser is used to parse a json object into a dictionary. In it's most basic form it takes a single `Value` parser, to be applied to each value in the json object. And the result after parsing will be a `[String: Value.Output]` dictionary, where `Value.Output` is the type returned from the `Value` parser.

```swift
let objectJson: JSONValue = .object([
  "url1": "https://www.example.com/1",
  "url2": "https://www.example.com/2",
  "url3": "https://www.example.com/3",
])

let dictionary = try JSONObject {
  URL.jsonParser()
}.parse(objectJson)
print(dictionary)
// ["url1": https://www.example.com/1, "url3": https://www.example.com/3, "url2": https://www.example.com/2]

try JSONObject {
  URL.jsonParser()
}.print(dictionary)
// .object(["url1": "https://www.example.com/1", "url3": "https://www.example.com/3", "url2": "https://www.example.com/2"])
```

But you can also specify custom parsing of the _keys_ into any `Hashable` type, by adding on a `keys` parser parameter:

```swift
let objectJson: JSONValue = [
  "key_1": "Steve Jobs",
  "key_2": "Tim Cook"
]

let dictionary = try JSONObject {
  String.jsonParser()
} keys: {
  "key_"
  Int.parser()
}.parse(objectJson)
print(dictionary)
// [1: "Steve Jobs", 2: "Tim Cook"]

try JSONObject {
  String.jsonParser()
} keys: {
  "key_"
  Int.parser()
}.print(dictionary)
// .object(["key_1": "Steve Jobs", "key_2": "Tim Cook"])
```

or by passing a string conversion to the initializer, for example a `representing` conversion to turn the keys into some `RawRepresentable` type:

```swift
struct UserID: RawRepresentable, Hashable {
  var rawValue: String
}
let usersJson: JSONValue = .object([
  "abc": "user 1",
  "def": "user 2",
])
let dictionary = try JSONObject(keys: .representing(UserID.self)) {
  String.jsonParser()
}.parse(usersJson)
print(dictionary)
// [UserID(rawValue: "abc"): "user 1", UserID(rawValue: "def"): "user 2"]

try JSONObject(keys: .representing(UserID.self)) {
  String.jsonParser()
}.print(dictionary)
// .object(["abc": "user 1", "def": "user 2"])
```

And just like the `JSONArray` parser, it can be restricted to only accept a certain number of elements (key/value pairs).

```swift
let emptyObjectJson: JSONValue = [:]
try JSONObject(1...) {
  URL.jsonParser()
}.parse(emptyObjectJson)
// throws: Expected at least 1 key/value pair in object, but found 0.

let emptyDictionary: [String: URL] = [:]
try JSONObject(1...) {
  URL.jsonParser()
}.print(emptyDictionary)
// throws: An JSONObject parser requiring at least 1 key/value pair was given 0 to print.
```

### Field

The `Field` parser is used for parsing a single value at a given field. It takes as input a key, as a `String`, and a json parser to be applied to the value found at that key.

```swift
let personJson: JSONValue = [
  "first_name": "Steve",
  "last_name": "Jobs",
  "age": 56,
]
let personJsonWithoutFirstName: JSONValue = [
  "last_name": "Cook",
  "age": 62,
]

try Field("first_name") {
  String.jsonParser()
}.parse(personJson)
// "Steve"

try Field("first_name") {
  String.jsonParser()
}.print("Steve")
// .object(["first_name": "Steve"])

try Field("first_name") {
  Int.jsonParser()
}.parse(personJson)
// throws:
// At "first_name":
// Expected an integer number, but found:
// "Steve"

try Field("first_name") {
  String.jsonParser()
}.parse(personJsonWithoutFirstName)
// throws:
// Key "first_name" not present.
```

Most often, you will probably want to combine multiple `Field` parsers together, to parse to a more complex result type. For the example above, you will likely have a `Person` type that you want to turn the json into. For that, we can make use of the `memberwise` conversion exposed from the *Parsing* library.

```swift
struct Person {
  let firstName: String
  let lastName: String
  let age: Int
}

extension Person {
  static var jsonParser: some JSONParserPrinter<Self> {
    try ParsePrint(.memberwise(Person.init)) {
      Field("first_name") { String.jsonParser() }
      Field("last_name") { String.jsonParser() }
      Field("age") { Int.jsonParser() }
    }
  }
}

let person = try Person.jsonParser.parse(personJson)
// Person(firstName: "Steve", lastName: "Jobs", age: 56)

try Person.jsonParser.print(person)
// .object(["first_name": "Steve", "last_name": "Jobs", "age": 56])
```

### OptionalField

The `OptionalField` parser works like the `Field` parser, but it allows for the field to not exist (or be `null`). To see what that is useful for, let's extend the `Person` type with a new field called `salary`:

```diff
struct Person {
  let firstName: String
  let lastName: String
  let age: Int
+ let salary: Double?
}
```

Then we can extend the `Person.jsonParser` in the following way:

```diff
try ParsePrint(.memberwise(Person.init)) {
  Field("first_name") { String.jsonParser() }
  Field("last_name") { String.jsonParser() }
  Field("age") { Int.jsonParser() }
+ OptionalField("salary") { Double.jsonParser() }
}
```

Now it can handle person json values with or without a salary.

```swift
let personJsonWithSalary: JSONValue = [
  "first_name": "Bob",
  "last_name": "Bobson",
  "age": 50,
  "salary": 12000
]
let personJsonWithoutSalary: JSONValue = [
  "first_name": "Mark",
  "last_name": "Markson",
  "age": 20
]

let person1 = try Person.jsonParser.parse(personJsonWithSalary)
// Person(firstName: "Bob", lastName: "Bobson", age: 50, salary: 12000.0)
try Person.jsonParser.print(person1)
// .object(["first_name": "Bob", "last_name": "Bobson", "age": 50, "salary": 12000.0])

let person2 = try Person.jsonParser.parse(personJsonWithoutSalary)
// Person(firstName: "Mark", lastName: "Markson", age: 20, salary: nil)
try Person.jsonParser.print(person2)
// .object(["first_name": "Mark", "last_name": "Markson", "age": 20])
```

Instead of treating an abscent value as `nil`, you can optionally provide a `default` value, to use as a fallback:

```diff
struct Person {
  let firstName: String
  let lastName: String
  let age: Int
- let salary: Double?
+ let salary: Double
}

extension Person {
  static var jsonParser: some JSONParserPrinter<Self> {
    try ParsePrint(.memberwise(Person.init)) {
      Field("first_name") { String.jsonParser() }
      Field("last_name") { String.jsonParser() }
      Field("age") { Int.jsonParser() }
-     OptionalField("salary") { Double.jsonParser() }
+     OptionalField("salary", default: 0) { Double.jsonParser() }
    }
  }
}
```

Now, parsing a person json without a salary, will use the default value of `0`:

```swift
let person = try Person.jsonParser.parse(personJsonWithoutSalary)
// Person(firstName: "Mark", lastName: "Markson", age: 20, salary: 0)
try Person.jsonParser.print(person)
// .object(["first_name": "Mark", "last_name": "Markson", "age": 20])
```

## Integration with Codable

While this library is intended to be able to stand on its own as a fully featured alternative to Codable, it does come with tools to help bridge these two worlds, allowing them to be mixed together. This is important partly because you may be working with other libraries that force you to use Codable in some places, and partly because it allows you to transition a code base that uses Codable, one model at a time. Let's take a look at how it works.

### Integrating *Codable* into *JSONParsing* code

Imagine that you have the following type:

```swift
struct Person {
  let name: String
  let age: Int
  let favoriteMovie: Movie?
}
```

where the `Movie` type is `Codable`, and you want to create a json parser for `Person`. For situations like this, the library extends all `Decodable` types with a `jsonParser(decoder:)` method, that takes an optional `JSONDecoder` parameter. And if the type also conforms to `Encodable`, the method takes an optional `JSONEncoder` parameter as well. So for our example, we can make use of this in the parse implementation, to deal with the `Movie` type:

```swift
extension Person {
  static var jsonParser: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      Field("name") { String.jsonParser() }
      Field("age") { Int.jsonParser() }
      Field("favorite_movie") { Movie.jsonParser() }
    }
  }
}
```

and if we need to customize the decoding/encoding of the `Movie` type, we can pass a custom decoder and/or encoder like this:

```swift
let jsonDecoder: JSONDecoder = ...
let jsonEncoder: JSONEncoder = ...
extension Person {
  static var jsonParser: some JSONParserPrinter<Self> {
    ParsePrint(.memberwise(Self.init)) {
      ...
      Field("favoriteMovie") { Movie.jsonParser(decoder: jsonDecoder, encoder: jsonEncoder) }
    }
  }
}
```

### Integrating *JSONParsing* into *Codable* code

So that's one part of the equation, when it comes to integration with Codable. But what about the other way around? What if we actually _do_ have a json parser capable of decoding `Movie`s, and we're using Codable for the `Person` type instead. For that usecase, the library comes with overloads of the various methods on the decoding/encoding containers, that take a json parser as input. Let's see what it looks like to use this, by conforming the `Person` type to both the `Decodable` and the `Encodable` protocol:

```swift
extension Person: Decodable {
  enum CodingKeys: String, CodingKey {
    case name
    case age
    case favoriteMovie = "favorite_movie"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.age = try container.decode(Int.self, forKey: .age)
    self.favoriteMovie = try container.decodeIfPresent(forKey: .favoriteMovie) {
      Movie.jsonParser
    }
  }
}

extension Person: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.name, forKey: .name)
    try container.encode(self.age, forKey: .age)
    try container.encodeIfPresent(self.favoriteMovie, forKey: .favoriteMovie) {
      Movie.jsonParser
    }
  }
}
```

Here, we make use of the overloads of the `KeyedDecodingContainer.decodeIfPresent`, and `KeyedEncodingContainer.encodeIfPresent` methods, that takes a json parser as input. Apart from taking an extra json parser parameter, the decoding overloads also make the `type` parameter optional, since it can always be inferred anyway. But if you want, you can still explicitly specify them like for the default versions:

```diff
extension Person: Decodable {
  ...
  init(from decoder: Decoder) throws {
    ...
-   self.favoriteMovie = try container.decodeIfPresent(forKey: .favoriteMovie) {
+   self.favoriteMovie = try container.decodeIfPresent(Movie.self, forKey: .favoriteMovie) {
      Movie.jsonParser
    }
  }
}
```

## Benchmarks

This library comes with a few benchmarks, comparing the execution time for decoding and encoding with that of the corresponding Codable implementation.

```text
MacBook Pro (14-inch, 2021)
Apple M1 Pro (10 cores, 8 performance and 2 efficiency)
16 GB (LPDDR5)

name                                     time           std        iterations
-----------------------------------------------------------------------------
Decoding.JSONDecoder (Codable)            174917.000 ns ±   3.19 %       7610
Decoding.JSONParser                       169625.000 ns ±   2.20 %       8070
Decoding.JSONParser (mixed with Codable)  311250.000 ns ±   8.36 %       4467
Decoding.JSONParser (from JSONValue)       67042.000 ns ±   2.06 %      20820
Encoding.JSONEncoder (Codable)           1212416.500 ns ±   0.96 %       1144
Encoding.JSONParser                      2082541.000 ns ±  22.11 %        680
Encoding.JSONParser (mixed with Codable) 2889500.000 ns ±  23.28 %        465
Encoding.JSONParser (to JSONValue)        397417.000 ns ±   1.09 %       3499
```

## Installation

You can add the library as a dependency using SPM by adding the following to the `Package.swift` file:

```swift
dependencies: [
  .package(url: "https://github.com/oskarek/swift-json-parsing", from: "0.1.0"),
]
```

and then in each module that needs access to it:

```swift
.target(
  name: "MyModule",
  dependencies: [
    .product(name: "JSONParsing", package: "swift-json-parsing"),
  ]
),
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
