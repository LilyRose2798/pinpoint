import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/string

pub opaque type Ipv4Address {
  Ipv4Address(value: String)
}

pub const v4_localhost = Ipv4Address("127.0.0.1")

pub fn parse_v4(value: String) -> Result(Ipv4Address, Nil) {
  let value = string.lowercase(value)
  case
    string.split(value, ".")
    |> list.try_map(fn(part) {
      case int.base_parse(part, 10) {
        Ok(x) if x >= 0 && x <= 255 -> Ok(x)
        _ -> Error(Nil)
      }
    })
  {
    Ok([_, _, _, _]) -> {
      Ok(Ipv4Address(value:))
    }
    _ -> Error(Nil)
  }
}

pub fn v4_decoder() -> Decoder(Ipv4Address) {
  use value <- decode.then(decode.string)
  case parse_v4(value) {
    Ok(ipv4_address) -> decode.success(ipv4_address)
    Error(Nil) -> decode.failure(v4_localhost, "Ipv4Address")
  }
}

pub fn v4_to_string(ipv4_address: Ipv4Address) -> String {
  ipv4_address.value
}

pub fn v4_encode(ipv4_address: Ipv4Address) -> Json {
  json.string(v4_to_string(ipv4_address))
}

pub opaque type Ipv6Address {
  Ipv6Address(value: String)
}

pub const v6_localhost = Ipv6Address("::1")

fn get_v6_parts(value: String) -> List(String) {
  string.split(value, on: ":")
}

fn parse_v6_parts(
  parts: List(String),
  value: String,
) -> Result(Ipv6Address, Nil) {
  case
    parts
    |> list.try_map(fn(part) {
      case int.base_parse(part, 16) {
        Ok(x) if x >= 0 && x <= 0xffff -> Ok(x)
        _ -> Error(Nil)
      }
    })
  {
    Ok([_, _, _, _, _, _, _, _]) -> Ok(Ipv6Address(value:))
    _ -> Error(Nil)
  }
}

pub fn parse_v6(value: String) -> Result(Ipv6Address, Nil) {
  let value = string.lowercase(value)
  case string.split(value, on: "::") {
    [left, right] -> {
      let left_parts = case left {
        "" -> []
        _ -> get_v6_parts(left)
      }
      let right_parts = case right {
        "" -> []
        _ -> get_v6_parts(right)
      }
      let omitted_parts = 8 - list.length(left_parts) - list.length(right_parts)
      use <- bool.guard(omitted_parts <= 0, Error(Nil))
      [left_parts, list.repeat("0", omitted_parts), right_parts]
      |> list.flatten
      |> parse_v6_parts(value)
    }
    [_] -> value |> get_v6_parts |> parse_v6_parts(value)
    _ -> Error(Nil)
  }
}

pub fn v6_decoder() -> Decoder(Ipv6Address) {
  use value <- decode.then(decode.string)
  case parse_v6(value) {
    Ok(ipv6_address) -> decode.success(ipv6_address)
    Error(Nil) -> decode.failure(v6_localhost, "Ipv6Address")
  }
}

pub fn v6_to_string(ipv6_address: Ipv6Address) -> String {
  ipv6_address.value
}

pub fn v6_encode(ipv6_address: Ipv6Address) -> Json {
  json.string(v6_to_string(ipv6_address))
}

pub type IpAddress {
  V4(address: Ipv4Address)
  V6(address: Ipv6Address)
}

pub fn parse(value: String) -> Result(IpAddress, Nil) {
  use <- result.lazy_or(parse_v4(value) |> result.map(V4))
  parse_v6(value) |> result.map(V6)
}

pub fn decoder() -> Decoder(IpAddress) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(ip_address) -> decode.success(ip_address)
    Error(Nil) -> decode.failure(V4(v4_localhost), "IpAddress")
  }
}

pub fn to_string(ip_address: IpAddress) -> String {
  case ip_address {
    V4(address) -> v4_to_string(address)
    V6(address) -> v6_to_string(address)
  }
}

pub fn encode(ip_address: IpAddress) -> Json {
  json.string(to_string(ip_address))
}
