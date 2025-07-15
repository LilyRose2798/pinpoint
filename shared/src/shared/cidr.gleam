import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/result
import gleam/string
import shared/ip_address.{type IpAddress, V4, V6}

pub opaque type Cidr {
  Cidr(ip_address: IpAddress, subnet: Int)
}

fn is_valid_subnet(ip_address: IpAddress, subnet: Int) {
  subnet >= 0
  && subnet
  <= case ip_address {
    V4(_) -> 32
    V6(_) -> 128
  }
}

pub fn new(ip_address: IpAddress, subnet: Int) -> Result(Cidr, Nil) {
  use <- bool.guard(!is_valid_subnet(ip_address, subnet), Error(Nil))
  Ok(Cidr(ip_address:, subnet:))
}

pub fn get_ip_address(cidr: Cidr) -> IpAddress {
  cidr.ip_address
}

pub fn get_subnet(cidr: Cidr) -> Int {
  cidr.subnet
}

pub fn parse(value: String) -> Result(Cidr, Nil) {
  use #(ip_address_str, subnet_str) <- result.try(string.split_once(value, "/"))
  use ip_address <- result.try(ip_address.parse(ip_address_str))
  use subnet <- result.try(int.parse(subnet_str))
  use <- bool.guard(!is_valid_subnet(ip_address, subnet), Error(Nil))
  Ok(Cidr(ip_address:, subnet:))
}

pub fn decoder() -> Decoder(Cidr) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(cidr) -> decode.success(cidr)
    Error(Nil) ->
      decode.failure(Cidr(ip_address.V4(ip_address.v4_localhost), 32), "Cidr")
  }
}

pub fn to_string(cidr: Cidr) {
  ip_address.to_string(cidr.ip_address) <> "/" <> int.to_string(cidr.subnet)
}

pub fn encode(cidr: Cidr) -> Json {
  json.string(to_string(cidr))
}
