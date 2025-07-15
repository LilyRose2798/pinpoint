import gleam/option.{type Option, None, Some}
import gleam/result

pub type FormField(a) {
  FormField(raw_value: String, parsed_value: Result(a, Nil))
}

pub fn parse(
  raw_value: String,
  value_parser: fn(String) -> Result(a, Nil),
) -> FormField(a) {
  FormField(raw_value:, parsed_value: value_parser(raw_value))
}

pub fn parse_optional(
  raw_value: String,
  value_parser: fn(String) -> Result(a, Nil),
) -> FormField(Option(a)) {
  FormField(raw_value:, parsed_value: case raw_value {
    "" -> Ok(None)
    _ -> value_parser(raw_value) |> result.map(Some)
  })
}
