import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/string

pub opaque type Postcode {
  Postcode(value: String)
}

pub fn parse(value: String) -> Result(Postcode, Nil) {
  use <- bool.guard(value == "", Error(Nil))
  use <- bool.guard(string.contains(value, ","), Error(Nil))
  Ok(Postcode(value:))
}

pub fn decoder() -> Decoder(Postcode) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(postcode) -> decode.success(postcode)
    Error(Nil) -> decode.failure(Postcode("invalid"), "Postcode")
  }
}

pub fn to_string(postcode: Postcode) -> String {
  postcode.value
}

pub fn encode(postcode: Postcode) -> Json {
  json.string(to_string(postcode))
}
