---
title: Edge and serverless targets
description: Build for Cloudflare, Deno, Vercel, Netlify, Lambda, Bun and more.
group: Deploy and run
order: 61
---

## Edge and serverless: `--target`

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target cloudflare               # dist/cloudflare (--out <folder>)
```

The app compiles to WebAssembly in a folder with the host's config, an entry
file and the static files; no wasm-bindgen or other tool.

| Target | For | From `dist/<target>` |
|---|---|---|
| `cloudflare` | Workers | `npx wrangler deploy` (secrets: `npx wrangler secret put WISP_SECRET`) |
| `pages` | Cloudflare Pages | `npx wrangler pages deploy .` in `dist/pages` (`_worker.js`, `_routes.json`; `WISP_SECRET` under Settings) |
| `deno` | Deno Deploy | `deployctl deploy --entrypoint main.ts` (local: `deno run -A main.ts`) |
| `vercel` | Vercel | `npx vercel deploy --prebuilt` (env var `WISP_SECRET`) |
| `netlify` | Netlify | `npx netlify deploy --prod` |
| `node` | Amplify, Firebase, Azure, Stormkit, Zeabur, any Node host | `npm start` |
| `bun` | Bun (`Bun.listen`) | `bun server.mjs` |
| `lambda` | AWS Lambda | below |

Vercel and Netlify Edge: add `--edge` (`--target vercel --edge`, `--target netlify --edge`); the wasm app runs as a module (`opt-level = "s"`, for their size limits), Netlify skips `static/` via `excludedPath`. Edge limits apply.

**Per route (Vercel, Netlify):** a route runs on the edge when its `+page.rs` or `+server.rs` says so; the rest stay on the Node function.

```rust
const RUNTIME: wisp::Runtime = wisp::Runtime::Edge;   // default: Node
```

With any Edge route, `wisp build --target vercel` (or `netlify`) writes both functions from the one app (the edge one built at `opt-level = "s"`) and routes each pattern to its own: `edge.func` beside `index.func` in `config.json`, or the edge function's `path` list. `static/` stays the CDN's. With no Edge route the output is unchanged. It must be a literal, and a layout cannot set it. Other hosts ignore it, and `--edge` puts every route there. The build stops, naming the route, if an Edge route uses what WebAssembly lacks (`std::fs`, `std::thread`, `std::process`, `std::net`, websockets).

The `node`, `bun` and local `deno` servers read raw sockets and the app's own
HTTP/1.1 parser answers (pipelining, keep-alive, chunked bodies, 413, 431 and
each route's `BODY_LIMIT`, as the native server has them), with no per-request
objects of the host's. At startup a request over loopback must be answered as
the app answers it (twice, on one connection); if not, or with
`WISP_NODE_HTTP=1`, they serve with `node:http`, `Bun.serve` or `Deno.serve`
(one stderr line says which). Deno Deploy has no sockets and always uses
`Deno.serve`. WebSockets are not served on any edge build (501). Only the
`node:http` path reads at most `WISP_BODY_LIMIT` (default 1 MB) of a body and
answers 413 past it.

- **Amplify, Firebase, Azure Static Web Apps, Stormkit, Zeabur:** `--target
  node` (`npm start`); the output's `hosts/*.md` has each host's manifest or
  function glue (Amplify: folder in `.amplify-hosting/compute/default/`,
  `static/` in `.amplify-hosting/static/`, a `deploy-manifest.json`).
- **GitHub/GitLab Pages:** `--static`, publish `dist/` (a project site under
  a path prefix needs prefix-safe links).
- **Fly.io:** `--docker`, `fly launch`, `fly deploy`, `fly secrets set WISP_SECRET=...`.
  **Railway, Render:** `--docker`, point at the repo, set `WISP_SECRET`.
  **Cloud Run:** `--docker`, `gcloud run deploy --source .`.
- **AWS Lambda:** `rustup target add x86_64-unknown-linux-musl` once;
  `--target lambda` writes `dist/lambda/bootstrap.zip` (the app's own static
  binary via Rust's lld; no C toolchain). Create the function once (runtime
  `provided.al2023`, `x86_64`, handler `bootstrap`) and add a Function URL
  (or API Gateway/ALB):

```sh
aws lambda create-function --function-name my-app --runtime provided.al2023 \
  --architectures x86_64 --handler bootstrap --role <role-arn> \
  --zip-file fileb://dist/lambda/bootstrap.zip
aws lambda update-function-code --function-name my-app --zip-file fileb://dist/lambda/bootstrap.zip
```

Any Wisp binary answers Lambda's runtime API when `AWS_LAMBDA_RUNTIME_API`
is set. Everything works except WebSockets and streaming (a stream is sent
whole). Saved tables go in `/tmp`, per instance: use `wisp::store` for
lasting data. The `tower` feature with `lambda_http` ([embed.md](/docs/embed))
also works.

### What works on the edge

No threads, sockets or files:

- Use `wisp::spawn` and `wisp::sleep`, not tokio's (they map to the host's
  task queue and `setTimeout`). `tokio::spawn`, `tokio::time`, sqlx, reqwest
  and `Response::file_in` answer 500 there; all work in the binary, Docker,
  Lambda.
- Background work: Cloudflare and Netlify keep the instance alive
  (`waitUntil`) for started timers and fetches; Deno and Node run on;
  Vercel may freeze after the response, so finish first.
- Saved tables (`Rest`, `Table::saved`) are per-instance memory unless
  `WISP_STORE` is set (no app code):

  | `WISP_STORE` | Store |
  |---|---|
  | `d1:DB` | Cloudflare D1 binding `DB` (`[[d1_databases]]` in wrangler.toml) |
  | `deno-kv` | Deno KV (`deno-kv:<path>` file or URL) |
  | `libsql://name.turso.io` | Turso or any libSQL server over HTTP, with `WISP_STORE_TOKEN` |

  Each instance reads every row at start (tables must fit in memory); a
  request's changes are one batch before the answer; a failed batch answers
  500 and the next request gets a fresh instance. Rows: SQL table
  `wisp_rows (tbl, id, json)`, or `["wisp", table, id]` in Deno KV.
- `WISP_SECRET` as a host secret. Read others with `wisp::env("KEY")`
  (`std::env::var` sees nothing; no `.env`).
- Streaming (`Response::stream`, `Response::events`) is live on Cloudflare,
  Deno, Netlify, Vercel, Node; a leaving client fails `send`.
- `Response::websocket` is 501 on every edge target (and `tower`); use SSE.
- `wisp::channel`, `wisp::every`, `RateLimit` are not in the edge build (it
  won't compile with them): use the host's queues, cron, rate limiting.
- Jobs: `wisp::cron` and `wisp::work` are the same code on every host.
  `wisp build` reads each `wisp::cron("0 3 * * *", ..)` of `src/` (the
  schedule must be a string literal) and writes the host's trigger: Cloudflare
  `[triggers] crons` in wrangler.toml, Vercel `crons` in config.json, a
  Netlify scheduled function a schedule. A trigger asks the app for
  `/_wisp/cron/<schedule>` with `Authorization: Bearer $CRON_SECRET` (set it
  as a host secret; without it the address is 404), which runs the tasks of
  that schedule and then every queue's due jobs: an app with `work` gets a
  trigger each minute (Vercel's Hobby plan allows daily ones only). The
  queue is a table, so queued jobs need `WISP_STORE`. Pages, Deno, Node, Bun,
  Lambda and Netlify `--edge` have no trigger to write: the build says so and
  stops; run the binary or Docker, which run jobs themselves.
- Outbound HTTP via `wisp::edge::fetch`:

  ```rust
  let mut req = wisp::Request::new("POST", "https://api.example.com/rows");
  req.header("authorization", &format!("Bearer {}", wisp::env("API_KEY").unwrap_or_default()));
  req.body = json.into_bytes();
  let reply = wisp::edge::fetch(req).await?;
  ```

- A panic fails only that request (500). No `Date` header from Wisp.
