import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import shared/cidr.{type Cidr}
import shared/city.{type City}
import shared/country_code.{type CountryCode}
import shared/postcode.{type Postcode}
import shared/region_code.{type RegionCode}

pub type GeofeedItem {
  GeofeedItem(
    cidr: Cidr,
    country: Option(CountryCode),
    region: Option(RegionCode),
    city: Option(City),
    postcode: Option(Postcode),
  )
}

pub fn decoder() -> Decoder(GeofeedItem) {
  use cidr <- decode.field("cidr", cidr.decoder())
  use country <- decode.optional_field(
    "country",
    None,
    decode.optional(country_code.decoder()),
  )
  use region <- decode.optional_field(
    "region",
    None,
    decode.optional(region_code.decoder()),
  )
  use city <- decode.optional_field(
    "city",
    None,
    decode.optional(city.decoder()),
  )
  use postcode <- decode.optional_field(
    "postcode",
    None,
    decode.optional(postcode.decoder()),
  )
  decode.success(GeofeedItem(cidr:, country:, region:, city:, postcode:))
}

pub fn encode(geofeed_item: GeofeedItem) -> Json {
  json.object([
    #("cidr", cidr.encode(geofeed_item.cidr)),
    #("country", json.nullable(geofeed_item.country, country_code.encode)),
    #("region", json.nullable(geofeed_item.region, region_code.encode)),
    #("city", json.nullable(geofeed_item.city, city.encode)),
    #("postcode", json.nullable(geofeed_item.postcode, postcode.encode)),
  ])
}

pub fn from_csv_line(line: String) -> Result(GeofeedItem, Nil) {
  let rest =
    line
    |> string.trim
    |> string.split(",")
  use #(cidr, rest) <- result.try(case rest {
    [] -> Error(Nil)
    [cidr, ..rest] -> cidr.parse(cidr) |> result.map(pair.new(_, rest))
  })
  use #(country, rest) <- result.try(case rest {
    [] -> Ok(#(None, []))
    ["", ..rest] -> Ok(#(None, rest))
    [country, ..rest] ->
      country_code.parse(country)
      |> result.map(Some)
      |> result.map(pair.new(_, rest))
  })
  use #(region, rest) <- result.try(case rest {
    [] -> Ok(#(None, []))
    ["", ..rest] -> Ok(#(None, rest))
    [region, ..rest] ->
      region_code.parse(region)
      |> result.map(Some)
      |> result.map(pair.new(_, rest))
  })
  use #(city, rest) <- result.try(case rest {
    [] -> Ok(#(None, []))
    ["", ..rest] -> Ok(#(None, rest))
    [city, ..rest] ->
      city.parse(city)
      |> result.map(Some)
      |> result.map(pair.new(_, rest))
  })
  use #(postcode, rest) <- result.try(case rest {
    [] -> Ok(#(None, []))
    ["", ..rest] -> Ok(#(None, rest))
    [postcode, ..rest] ->
      postcode.parse(postcode)
      |> result.map(Some)
      |> result.map(pair.new(_, rest))
  })
  use <- bool.guard(rest != [], Error(Nil))
  Ok(GeofeedItem(cidr:, country:, region:, city:, postcode:))
}

pub fn to_csv_line(item: GeofeedItem) -> String {
  [
    cidr.to_string(item.cidr),
    case item.country {
      Some(country) -> country_code.to_string(country)
      None -> ""
    },
    case item.region {
      Some(region) -> region_code.to_string(region)
      None -> ""
    },
    case item.city {
      Some(city) -> city.to_string(city)
      None -> ""
    },
    case item.postcode {
      Some(postcode) -> postcode.to_string(postcode)
      None -> ""
    },
  ]
  |> string.join(",")
}
