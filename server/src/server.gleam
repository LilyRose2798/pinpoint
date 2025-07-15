import argv
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/int
import gleam/json
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import shared
import shared/geofeed
import simplifile
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(priv_directory) = wisp.priv_directory("server")
  let static_directory = priv_directory <> "/static"
  let assert [port_str, geofeed_path, ..] = argv.load().arguments
  let assert Ok(port) = int.parse(port_str)
  let assert Ok(_) =
    handle_request(static_directory, geofeed_path, _)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start
  process.sleep_forever()
}

fn app_middleware(
  req: Request,
  static_directory: String,
  next: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: static_directory)
  next(req)
}

fn handle_request(
  static_directory: String,
  geofeed_path: String,
  req: Request,
) -> Response {
  use req <- app_middleware(req, static_directory)
  case req.method, wisp.path_segments(req) {
    Post, ["api", "geofeed"] -> handle_save_geofeed(req, geofeed_path)
    Get, _ -> serve_index(geofeed_path)
    _, _ -> wisp.not_found()
  }
}

fn serve_index(geofeed_path: String) -> Response {
  html.html(
    [
      attribute.styles([
        #("color-scheme", "dark light"),
        shared.font_family_style,
      ]),
    ],
    [
      html.head([], [
        html.title([], "Pinpoint - Geofeed Editor"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/client.mjs")],
          "",
        ),
      ]),
      html.script(
        [
          attribute.type_("application/json"),
          attribute.id(shared.model_element_id),
        ],
        json.to_string(
          geofeed.encode(case simplifile.read(geofeed_path) {
            Ok(csv) -> geofeed.from_csv(csv)
            Error(_) -> []
          }),
        ),
      ),
      html.body([attribute.styles([#("margin", "0"), #("padding", "0")])], [
        html.div([attribute.id(shared.app_element_id)], []),
      ]),
    ],
  )
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn handle_save_geofeed(req: Request, geofeed_path: String) -> Response {
  use json <- wisp.require_json(req)
  case decode.run(json, geofeed.decoder()) {
    Ok(geofeed) ->
      case simplifile.write(geofeed_path, geofeed.to_csv(geofeed)) {
        Ok(_) -> wisp.ok()
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request()
  }
}
