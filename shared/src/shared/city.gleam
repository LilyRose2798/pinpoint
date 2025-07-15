import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/string

pub opaque type City {
  City(value: String)
}

pub fn parse(value: String) -> Result(City, Nil) {
  use <- bool.guard(value == "", Error(Nil))
  use <- bool.guard(string.contains(value, ","), Error(Nil))
  Ok(City(value:))
}

pub fn decoder() -> Decoder(City) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(city) -> decode.success(city)
    Error(Nil) -> decode.failure(City("invalid"), "City")
  }
}

pub fn to_string(city: City) -> String {
  city.value
}

pub fn encode(city: City) -> Json {
  json.string(to_string(city))
}
