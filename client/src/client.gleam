import client/form_field.{type FormField, FormField}
import client/geofeed_form.{type GeofeedForm}
import client/geofeed_form_item.{type GeofeedFormItem, GeofeedFormItem}
import gleam/dict
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event
import plinth/browser/document
import plinth/browser/element as plinth_element
import rsvp
import shared
import shared/cidr
import shared/city
import shared/country_code
import shared/geofeed
import shared/postcode
import shared/region_code

pub fn main() {
  let geofeed =
    document.query_selector("#" <> shared.model_element_id)
    |> result.map(plinth_element.inner_text)
    |> result.try(fn(json) {
      json.parse(json, geofeed.decoder())
      |> result.replace_error(Nil)
    })
    |> result.unwrap([])
  let app = lustre.application(init, update, view)
  let assert Ok(_) =
    lustre.start(
      app,
      "#" <> shared.app_element_id,
      geofeed_form.from_geofeed(geofeed),
    )
  Nil
}

type GeofeedSearchItem {
  GeofeedSearchItem(
    cidr: String,
    country: String,
    region: String,
    city: String,
    postcode: String,
  )
}

type Model {
  Model(
    geofeed_form: GeofeedForm,
    search_item: GeofeedSearchItem,
    show_postcode: Bool,
    saving: Bool,
    errors: List(String),
  )
}

fn init(geofeed_form: GeofeedForm) -> #(Model, Effect(Msg)) {
  let search_item =
    GeofeedSearchItem(cidr: "", country: "", region: "", city: "", postcode: "")
  let model =
    Model(
      geofeed_form:,
      search_item:,
      show_postcode: False,
      saving: False,
      errors: [],
    )
  #(model, effect.none())
}

type Msg {
  ServerSavedList(Result(Response(String), rsvp.Error))
  UserSavedList
  UserAddedItem(index: Option(Int))
  UserMovedItemUp(index: Int)
  UserMovedItemDown(index: Int)
  UserDeletedItem(index: Int)
  UserUpdatedItem(index: Int, item: GeofeedFormItem)
  UserUpdatedSearchItem(search_item: GeofeedSearchItem)
  UserSetShowPostcode(show_postcode: Bool)
}

fn prepend_form_field_errors(
  errors errors: List(String),
  form_field form_field: FormField(a),
  index index: Int,
  field_name field_name: String,
) -> List(String) {
  case form_field.parsed_value {
    Ok(_) -> errors
    Error(_) -> [
      "Invalid " <> field_name <> " at position " <> int.to_string(index + 1),
      ..errors
    ]
  }
}

fn get_errors(model: Model) -> List(String) {
  let errors =
    list.index_fold(model.geofeed_form, [], fn(acc, item, index) {
      acc
      |> prepend_form_field_errors(
        form_field: item.cidr,
        index:,
        field_name: "CIDR",
      )
      |> prepend_form_field_errors(
        form_field: item.country,
        index:,
        field_name: "country code",
      )
      |> prepend_form_field_errors(
        form_field: item.region,
        index:,
        field_name: "region code",
      )
      |> prepend_form_field_errors(
        form_field: item.city,
        index:,
        field_name: "city",
      )
      |> prepend_form_field_errors(
        form_field: item.postcode,
        index:,
        field_name: "postcode",
      )
    })
  let errors =
    list.index_fold(model.geofeed_form, #(errors, dict.new()), fn(acc, item, i) {
      case item.cidr.parsed_value {
        Ok(cidr) -> #(
          case acc.1 |> dict.get(cidr) {
            Ok(j) -> [
              "Duplicate CIDR at position "
                <> int.to_string(i + 1)
                <> " (same as position "
                <> int.to_string(j + 1)
                <> ")",
              ..acc.0
            ]
            Error(Nil) -> acc.0
          },
          acc.1 |> dict.insert(cidr, i),
        )
        Error(Nil) -> acc
      }
    }).0
  list.reverse(errors)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ServerSavedList(Ok(_)) -> #(
      Model(..model, saving: False, errors: []),
      effect.none(),
    )
    ServerSavedList(Error(_)) -> #(
      Model(..model, saving: False, errors: ["Failed to save list"]),
      effect.none(),
    )
    UserSavedList -> {
      case get_errors(model) {
        [] -> #(Model(..model, saving: True), {
          let url = "/api/geofeed"
          let body =
            model.geofeed_form |> geofeed_form.to_geofeed |> geofeed.encode
          rsvp.post(url, body, rsvp.expect_ok_response(ServerSavedList))
        })
        errors -> #(Model(..model, errors:), effect.none())
      }
    }
    UserAddedItem(index:) -> {
      let new_item =
        GeofeedFormItem(
          cidr: FormField(raw_value: "", parsed_value: Error(Nil)),
          country: FormField(raw_value: "", parsed_value: Ok(None)),
          region: FormField(raw_value: "", parsed_value: Ok(None)),
          city: FormField(raw_value: "", parsed_value: Ok(None)),
          postcode: FormField(raw_value: "", parsed_value: Ok(None)),
        )
      let geofeed_form = case index {
        Some(index) ->
          list.index_fold(model.geofeed_form, [], fn(acc, item, i) {
            case i == index {
              True -> [item, new_item, ..acc]
              False -> [item, ..acc]
            }
          })
          |> list.reverse
        None -> list.append(model.geofeed_form, [new_item])
      }
      #(Model(..model, geofeed_form:), effect.none())
    }
    UserMovedItemUp(index:) -> {
      let geofeed_form =
        list.index_fold(model.geofeed_form, [], fn(acc, cur, i) {
          case i == index, acc {
            True, [] -> [cur, ..acc]
            True, [prev, ..rest] -> [prev, cur, ..rest]
            False, _ -> [cur, ..acc]
          }
        })
        |> list.reverse
      #(Model(..model, geofeed_form:), effect.none())
    }
    UserMovedItemDown(index:) -> {
      let index = list.length(model.geofeed_form) - index - 1
      let geofeed_form =
        list.index_fold(list.reverse(model.geofeed_form), [], fn(acc, cur, i) {
          case i == index, acc {
            True, [] -> [cur, ..acc]
            True, [prev, ..rest] -> [prev, cur, ..rest]
            False, _ -> [cur, ..acc]
          }
        })
      #(Model(..model, geofeed_form:), effect.none())
    }
    UserDeletedItem(index:) -> {
      let geofeed_form =
        list.index_fold(model.geofeed_form, [], fn(acc, cur, i) {
          case i != index {
            True -> [cur, ..acc]
            False -> acc
          }
        })
        |> list.reverse
      #(Model(..model, geofeed_form:), effect.none())
    }
    UserUpdatedItem(index:, item:) -> {
      let geofeed_form =
        list.index_map(model.geofeed_form, fn(cur_item, item_index) {
          case item_index == index {
            True -> item
            False -> cur_item
          }
        })
      #(Model(..model, geofeed_form:), effect.none())
    }
    UserUpdatedSearchItem(search_item:) -> {
      #(Model(..model, search_item:), effect.none())
    }
    UserSetShowPostcode(show_postcode:) -> {
      #(Model(..model, show_postcode:), effect.none())
    }
  }
}

const default_font_size_style = #("font-size", "0.9em")

const text_align_center_style = #("text-align", "center")

const border_style = #("border", "1px solid #8f8f9d")

const border_radius_style = #("border-radius", "0.5em")

const cursor_pointer_style = #("cursor", "pointer")

fn form_button(
  on_click_msg on_click_msg: Msg,
  text text: String,
) -> Element(Msg) {
  html.button(
    [
      event.on_click(on_click_msg),
      attribute.styles([
        #("padding", "0.4em 1em"),
        shared.font_family_style,
        default_font_size_style,
        border_style,
        border_radius_style,
        cursor_pointer_style,
      ]),
    ],
    [html.text(text)],
  )
}

fn view(model: Model) -> Element(Msg) {
  let Model(geofeed_form:, search_item:, show_postcode:, saving:, errors:) =
    model
  element.fragment([
    html.h1(
      [
        attribute.styles([
          #("margin", "0.5em 0 0 0"),
          text_align_center_style,
          shared.font_family_style,
        ]),
      ],
      [html.text("Pinpoint 📌")],
    ),
    html.h2(
      [
        attribute.styles([
          #("margin", "0.3em 0 0 0"),
          text_align_center_style,
          shared.font_family_style,
        ]),
      ],
      [html.text("Geofeed Editor")],
    ),
    html.div(
      [
        attribute.styles([
          #("margin", "0.5em 0 0 0"),
          text_align_center_style,
          shared.font_family_style,
          #("font-size", "1em"),
        ]),
      ],
      [
        html.a(
          [attribute.href("https://www.iso.org/obp/ui/#iso:pub:PUB500001:en")],
          [html.text("View ISO Country/Region Codes")],
        ),
      ],
    ),
    html.div(
      [attribute.styles([#("display", "flex"), #("justify-content", "center")])],
      [view_geofeed_form(geofeed_form:, search_item:, show_postcode:)],
    ),
    element.fragment(
      errors
      |> list.map(fn(error) {
        html.div(
          [
            attribute.styles([
              shared.error_font_color_style,
              shared.font_family_style,
              default_font_size_style,
              text_align_center_style,
              #("margin-bottom", "1em"),
            ]),
          ],
          [html.text(error)],
        )
      }),
    ),
    html.div(
      [
        attribute.styles([
          #("margin-bottom", "1em"),
          #("display", "flex"),
          #("justify-content", "center"),
          #("gap", "0.6em"),
        ]),
      ],
      [
        form_button(on_click_msg: UserAddedItem(None), text: "Add"),
        form_button(on_click_msg: UserSavedList, text: case saving {
          True -> "Saving..."
          False -> "Save"
        }),
        html.label(
          [
            attribute.styles([
              #("padding", "0.4em 1em 0.4em 0.7em"),
              shared.font_family_style,
              default_font_size_style,
              border_style,
              border_radius_style,
            ]),
          ],
          [
            html.input([
              attribute.type_("checkbox"),
              event.on_check(UserSetShowPostcode),
            ]),
            html.text("Postcode"),
          ],
        ),
      ],
    ),
  ])
}

fn input(
  value value: String,
  is_valid is_valid: Bool,
  chars chars: Int,
  set_max_length set_max_length: Bool,
  placeholder placeholder: String,
  on_input_handler on_input_handler: fn(String) -> Msg,
) {
  html.input([
    attribute.styles([
      #("padding", "0.4em 0.6em"),
      #("width", int.to_string(chars) <> "ch"),
      shared.font_family_style,
      default_font_size_style,
      border_style,
      border_radius_style,
      ..case is_valid {
        True -> []
        False -> [shared.error_font_color_style]
      }
    ]),
    attribute.placeholder(placeholder),
    attribute.value(value),
    event.on_input(on_input_handler),
    ..case set_max_length {
      True -> [attribute.maxlength(chars)]
      False -> []
    }
  ])
}

fn form_field_input(
  form_field form_field: FormField(a),
  chars chars: Int,
  set_max_length set_max_length: Bool,
  placeholder placeholder: String,
  on_input_handler on_input_handler: fn(String) -> Msg,
) {
  input(
    value: form_field.raw_value,
    is_valid: result.is_ok(form_field.parsed_value),
    chars:,
    set_max_length:,
    placeholder:,
    on_input_handler:,
  )
}

fn field_search(
  value value: String,
  form_field form_field: FormField(a),
) -> Bool {
  value == ""
  || string.contains(
    does: string.lowercase(form_field.raw_value),
    contain: string.lowercase(value),
  )
}

fn item_search(
  search_item search_item: GeofeedSearchItem,
  item item: GeofeedFormItem,
) -> Bool {
  field_search(value: search_item.cidr, form_field: item.cidr)
  && field_search(value: search_item.country, form_field: item.country)
  && field_search(value: search_item.region, form_field: item.region)
  && field_search(value: search_item.city, form_field: item.city)
  && field_search(value: search_item.postcode, form_field: item.postcode)
}

fn view_geofeed_form(
  geofeed_form geofeed_form: GeofeedForm,
  search_item search_item: GeofeedSearchItem,
  show_postcode show_postcode: Bool,
) -> Element(Msg) {
  case geofeed_form {
    [] ->
      html.p([attribute.styles([text_align_center_style])], [
        html.text("No items in your geofeed yet."),
      ])
    _ -> {
      let total = list.length(geofeed_form)
      html.div([], [
        html.div(
          [
            attribute.styles([
              #("margin", "1em 0"),
              #("display", "flex"),
              #("gap", "0.6em"),
            ]),
          ],
          [
            input(
              value: search_item.cidr,
              is_valid: True,
              chars: 43,
              set_max_length: True,
              placeholder: "CIDR",
              on_input_handler: fn(value) {
                UserUpdatedSearchItem(
                  GeofeedSearchItem(
                    ..search_item,
                    cidr: string.lowercase(value),
                  ),
                )
              },
            ),
            input(
              value: search_item.country,
              is_valid: True,
              chars: 2,
              set_max_length: True,
              placeholder: "CC",
              on_input_handler: fn(value) {
                UserUpdatedSearchItem(
                  GeofeedSearchItem(
                    ..search_item,
                    country: string.uppercase(value),
                  ),
                )
              },
            ),
            input(
              value: search_item.region,
              is_valid: True,
              chars: 6,
              set_max_length: True,
              placeholder: "Region",
              on_input_handler: fn(value) {
                UserUpdatedSearchItem(
                  GeofeedSearchItem(
                    ..search_item,
                    region: string.uppercase(value),
                  ),
                )
              },
            ),
            input(
              value: search_item.city,
              is_valid: True,
              chars: 24,
              set_max_length: False,
              placeholder: "City",
              on_input_handler: fn(value) {
                UserUpdatedSearchItem(
                  GeofeedSearchItem(..search_item, city: value),
                )
              },
            ),
            ..case show_postcode {
              True -> [
                input(
                  value: search_item.postcode,
                  is_valid: True,
                  chars: 10,
                  set_max_length: False,
                  placeholder: "Postcode",
                  on_input_handler: fn(value) {
                    UserUpdatedSearchItem(
                      GeofeedSearchItem(..search_item, postcode: value),
                    )
                  },
                ),
              ]
              False -> []
            }
          ],
        ),
        case list.any(geofeed_form, item_search(search_item:, item: _)) {
          True ->
            html.ol(
              [attribute.styles([#("margin", "0"), #("padding", "0")])],
              list.index_map(geofeed_form, fn(item, index) {
                html.li(
                  [
                    attribute.value(int.to_string(index + 1)),
                    ..case item_search(search_item:, item:) {
                      True -> []
                      False -> [attribute.styles([#("display", "none")])]
                    }
                  ],
                  [view_geofeed_item(item:, index:, total:, show_postcode:)],
                )
              }),
            )
          False ->
            html.p([attribute.styles([text_align_center_style])], [
              html.text("Search returned no results."),
            ])
        },
      ])
    }
  }
}

fn item_button(
  on_click_msg on_click_msg: Msg,
  disabled disabled: Bool,
  icon_path icon_path: String,
) -> Element(Msg) {
  html.button(
    [
      event.on_click(on_click_msg),
      attribute.disabled(disabled),
      attribute.styles([
        #("padding", "0 0.3em"),
        #("display", "inline-flex"),
        #("align-items", "center"),
        shared.font_family_style,
        #("font-size", "1.2em"),
        border_style,
        border_radius_style,
        ..case disabled {
          True -> []
          False -> [cursor_pointer_style]
        }
      ]),
    ],
    [
      html.svg(
        [
          attribute.attribute("viewBox", "0 0 512 512"),
          attribute.attribute("fill", "white"),
          attribute.styles([#("width", "1em")]),
        ],
        [svg.path([attribute.attribute("d", icon_path)])],
      ),
    ],
  )
}

fn view_geofeed_item(
  item item: GeofeedFormItem,
  index index: Int,
  total total: Int,
  show_postcode show_postcode: Bool,
) -> Element(Msg) {
  let item_buttons = [
    item_button(
      on_click_msg: UserMovedItemUp(index:),
      disabled: index == 0,
      icon_path: "m233.4 137.4c12.5-12.5 32.8-12.5 45.3 0l160 160c12.5 12.5 12.5 32.8 0 45.3s-32.8 12.5-45.3 0l-137.4-137.4-137.4 137.3c-12.5 12.5-32.8 12.5-45.3 0s-12.5-32.8 0-45.3l160-160z",
    ),
    item_button(
      on_click_msg: UserMovedItemDown(index:),
      disabled: index == total - 1,
      icon_path: "m233.4 374.6c12.5 12.5 32.8 12.5 45.3 0l160-160c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0l-137.4 137.4-137.4-137.3c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3l160 160z",
    ),
    item_button(
      on_click_msg: UserAddedItem(index: Some(index)),
      disabled: False,
      icon_path: "m288 80c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 144-144 0c-17.7 0-32 14.3-32 32s14.3 32 32 32l144 0 0 144c0 17.7 14.3 32 32 32s32-14.3 32-32l0-144 144 0c17.7 0 32-14.3 32-32s-14.3-32-32-32l-144 0 0-144z",
    ),
    item_button(
      on_click_msg: UserDeletedItem(index:),
      disabled: False,
      icon_path: "m406.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0l-105.3 105.4-105.4-105.3c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3l105.4 105.3-105.3 105.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l105.3-105.4 105.4 105.3c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3l-105.4-105.3 105.3-105.4z",
    ),
  ]
  html.div(
    [
      attribute.styles([
        #("margin", "1em 0"),
        #("display", "flex"),
        #("gap", "0.6em"),
      ]),
    ],
    [
      form_field_input(
        form_field: item.cidr,
        chars: 43,
        set_max_length: True,
        placeholder: "CIDR",
        on_input_handler: fn(value) {
          UserUpdatedItem(
            index,
            GeofeedFormItem(
              ..item,
              cidr: form_field.parse(string.lowercase(value), cidr.parse),
            ),
          )
        },
      ),
      form_field_input(
        form_field: item.country,
        chars: 2,
        set_max_length: True,
        placeholder: "CC",
        on_input_handler: fn(value) {
          UserUpdatedItem(
            index,
            GeofeedFormItem(
              ..item,
              country: form_field.parse_optional(
                string.uppercase(value),
                country_code.parse,
              ),
            ),
          )
        },
      ),
      form_field_input(
        form_field: item.region,
        chars: 6,
        set_max_length: True,
        placeholder: "Region",
        on_input_handler: fn(value) {
          UserUpdatedItem(
            index,
            GeofeedFormItem(
              ..item,
              region: form_field.parse_optional(
                string.uppercase(value),
                region_code.parse,
              ),
            ),
          )
        },
      ),
      form_field_input(
        form_field: item.city,
        chars: 24,
        set_max_length: False,
        placeholder: "City",
        on_input_handler: fn(value) {
          UserUpdatedItem(
            index,
            GeofeedFormItem(
              ..item,
              city: form_field.parse_optional(value, city.parse),
            ),
          )
        },
      ),
      ..case show_postcode {
        True -> [
          form_field_input(
            form_field: item.postcode,
            chars: 10,
            set_max_length: False,
            placeholder: "Postcode",
            on_input_handler: fn(value) {
              UserUpdatedItem(
                index,
                GeofeedFormItem(
                  ..item,
                  postcode: form_field.parse_optional(value, postcode.parse),
                ),
              )
            },
          ),
          ..item_buttons
        ]
        False -> item_buttons
      }
    ],
  )
}
