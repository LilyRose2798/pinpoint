import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/result
import gleam/string

pub opaque type CountryCode {
  CountryCode(value: String)
}

fn parse_alphabetic(value: String) -> Result(String, Nil) {
  case value {
    "A" <> rest -> Ok(rest)
    "B" <> rest -> Ok(rest)
    "C" <> rest -> Ok(rest)
    "D" <> rest -> Ok(rest)
    "E" <> rest -> Ok(rest)
    "F" <> rest -> Ok(rest)
    "G" <> rest -> Ok(rest)
    "H" <> rest -> Ok(rest)
    "I" <> rest -> Ok(rest)
    "J" <> rest -> Ok(rest)
    "K" <> rest -> Ok(rest)
    "L" <> rest -> Ok(rest)
    "M" <> rest -> Ok(rest)
    "N" <> rest -> Ok(rest)
    "O" <> rest -> Ok(rest)
    "P" <> rest -> Ok(rest)
    "Q" <> rest -> Ok(rest)
    "R" <> rest -> Ok(rest)
    "S" <> rest -> Ok(rest)
    "T" <> rest -> Ok(rest)
    "U" <> rest -> Ok(rest)
    "V" <> rest -> Ok(rest)
    "W" <> rest -> Ok(rest)
    "X" <> rest -> Ok(rest)
    "Y" <> rest -> Ok(rest)
    "Z" <> rest -> Ok(rest)
    _ -> Error(Nil)
  }
}

pub fn parse(value: String) -> Result(CountryCode, Nil) {
  let value = string.uppercase(value)
  use rest <- result.try(parse_alphabetic(value))
  use rest <- result.try(parse_alphabetic(rest))
  use <- bool.guard(rest != "", Error(Nil))
  Ok(CountryCode(value:))
}

pub fn decoder() -> Decoder(CountryCode) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(country_code) -> decode.success(country_code)
    Error(Nil) -> decode.failure(CountryCode("invalid"), "CountryCode")
  }
}

pub fn to_string(country_code: CountryCode) -> String {
  country_code.value
}

pub fn encode(country_code: CountryCode) -> Json {
  json.string(to_string(country_code))
}
