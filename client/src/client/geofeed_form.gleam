import client/geofeed_form_item.{type GeofeedFormItem}
import gleam/list
import gleam/result
import shared/geofeed.{type Geofeed}

pub type GeofeedForm =
  List(GeofeedFormItem)

pub fn from_geofeed(geofeed: Geofeed) -> GeofeedForm {
  geofeed |> list.map(geofeed_form_item.from_geofeed_item)
}

pub fn to_geofeed(geofeed_form: GeofeedForm) -> Geofeed {
  geofeed_form |> list.map(geofeed_form_item.to_geofeed_item) |> result.values
}
