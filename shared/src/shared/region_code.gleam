import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/result
import gleam/string

pub opaque type RegionCode {
  RegionCode(value: String)
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

fn parse_alphanumeric(value: String) -> Result(String, Nil) {
  case value {
    "0" <> rest -> Ok(rest)
    "1" <> rest -> Ok(rest)
    "2" <> rest -> Ok(rest)
    "3" <> rest -> Ok(rest)
    "4" <> rest -> Ok(rest)
    "5" <> rest -> Ok(rest)
    "6" <> rest -> Ok(rest)
    "7" <> rest -> Ok(rest)
    "8" <> rest -> Ok(rest)
    "9" <> rest -> Ok(rest)
    _ -> parse_alphabetic(value)
  }
}

fn parse_optional_alphanumeric(value: String) -> Result(String, Nil) {
  case value {
    "" -> Ok("")
    _ -> parse_alphanumeric(value)
  }
}

pub fn parse(value: String) -> Result(RegionCode, Nil) {
  let value = string.uppercase(value)
  use rest <- result.try(parse_alphabetic(value))
  use rest <- result.try(parse_alphabetic(rest))
  use rest <- result.try(case rest {
    "-" <> rest -> Ok(rest)
    _ -> Error(Nil)
  })
  use rest <- result.try(parse_alphanumeric(rest))
  use rest <- result.try(parse_optional_alphanumeric(rest))
  use rest <- result.try(parse_optional_alphanumeric(rest))
  use <- bool.guard(rest != "", Error(Nil))
  Ok(RegionCode(value:))
}

pub fn decoder() -> Decoder(RegionCode) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(region_code) -> decode.success(region_code)
    Error(Nil) -> decode.failure(RegionCode("invalid"), "RegionCode")
  }
}

pub fn to_string(region_code: RegionCode) -> String {
  region_code.value
}

pub fn encode(region_code: RegionCode) -> Json {
  json.string(to_string(region_code))
}
