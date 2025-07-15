# pinpoint

```sh
cd client
gleam run -m lustre/dev build --outdir=../server/priv/static # Build the client
cd ..
cd server
gleam run <port> <geofeed_path> # Run the server
```
