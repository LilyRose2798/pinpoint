import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/string
import shared/geofeed_item.{type GeofeedItem}

pub type Geofeed =
  List(GeofeedItem)

pub fn decoder() -> Decoder(Geofeed) {
  decode.list(geofeed_item.decoder())
}

pub fn encode(geofeed: Geofeed) -> Json {
  json.array(geofeed, geofeed_item.encode)
}

pub fn from_csv(csv: String) -> Geofeed {
  csv
  |> string.trim
  |> string.split("\n")
  |> list.map(geofeed_item.from_csv_line)
  |> result.values
}

pub fn to_csv(geofeed: Geofeed) -> String {
  geofeed
  |> list.map(geofeed_item.to_csv_line)
  |> string.join("\n")
}
