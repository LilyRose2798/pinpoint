import client/form_field.{type FormField, FormField}
import gleam/option.{type Option, None, Some}
import gleam/result
import shared/cidr.{type Cidr}
import shared/city.{type City}
import shared/country_code.{type CountryCode}
import shared/geofeed_item.{type GeofeedItem, GeofeedItem}
import shared/postcode.{type Postcode}
import shared/region_code.{type RegionCode}

pub type GeofeedFormItem {
  GeofeedFormItem(
    cidr: FormField(Cidr),
    country: FormField(Option(CountryCode)),
    region: FormField(Option(RegionCode)),
    city: FormField(Option(City)),
    postcode: FormField(Option(Postcode)),
  )
}

pub fn from_geofeed_item(item: GeofeedItem) -> GeofeedFormItem {
  GeofeedFormItem(
    cidr: FormField(
      raw_value: cidr.to_string(item.cidr),
      parsed_value: Ok(item.cidr),
    ),
    country: FormField(
      raw_value: case item.country {
        Some(country) -> country_code.to_string(country)
        None -> ""
      },
      parsed_value: Ok(item.country),
    ),
    region: FormField(
      raw_value: case item.region {
        Some(region) -> region_code.to_string(region)
        None -> ""
      },
      parsed_value: Ok(item.region),
    ),
    city: FormField(
      raw_value: case item.city {
        Some(city) -> city.to_string(city)
        None -> ""
      },
      parsed_value: Ok(item.city),
    ),
    postcode: FormField(
      raw_value: case item.postcode {
        Some(postcode) -> postcode.to_string(postcode)
        None -> ""
      },
      parsed_value: Ok(item.postcode),
    ),
  )
}

pub fn to_geofeed_item(item: GeofeedFormItem) -> Result(GeofeedItem, Nil) {
  use cidr <- result.try(item.cidr.parsed_value)
  use country <- result.try(item.country.parsed_value)
  use region <- result.try(item.region.parsed_value)
  use city <- result.try(item.city.parsed_value)
  use postcode <- result.try(item.postcode.parsed_value)
  Ok(GeofeedItem(cidr:, country:, region:, city:, postcode:))
}
