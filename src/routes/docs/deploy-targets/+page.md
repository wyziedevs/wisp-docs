---
title: Edge and Serverless Targets
description: Build Wisp for Cloudflare, Deno, Vercel, Netlify, AWS Lambda, Bun and Node, choose an edge runtime per route and see which features work on the edge.
group: Deploy and Run
order: 61
---

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target cloudflare               # dist/cloudflare (--out <folder>)
```

The app compiles to WebAssembly in a folder with the host's config, an entry file and the static files. No wasm-bindgen or other tool.

<div class="table-wrap">

| Target | For | From `dist/<target>` |
|---|---|---|
| `cloudflare` | [Workers](/docs/hosting/cloudflare/) | `npx wrangler deploy` (secrets: `npx wrangler secret put WISP_SECRET`) |
| `pages` | [Cloudflare Pages](/docs/hosting/cloudflare/) | `npx wrangler pages deploy .` in `dist/pages` (`_worker.js`, `_routes.json`; `WISP_SECRET` under Settings) |
| `deno` | [Deno Deploy](/docs/hosting/deno-deploy/) | `deployctl deploy --entrypoint main.ts` (local: `deno run -A main.ts`) |
| `vercel` | [Vercel](/docs/hosting/vercel/) | `npx vercel deploy --prebuilt` (env var `WISP_SECRET`) |
| `netlify` | [Netlify](/docs/hosting/netlify/) | `npx netlify deploy --prod` |
| `node` | Amplify, Firebase, [Azure](/docs/hosting/azure/), Stormkit, Zeabur, any [Node](/docs/hosting/node/) host | `npm start` |
| `bun` | [Bun](/docs/hosting/bun/) (`Bun.listen`) | `bun server.mjs` |
| `lambda` | [AWS Lambda](/docs/hosting/aws-lambda/) | [below](#aws-lambda) |

</div>

Other hosts (each has a page under [Hosting](/docs/hosting/)):

<div class="table-wrap">

| Host | Use |
|---|---|
| Amplify, Firebase, Azure Static Web Apps, Stormkit, Zeabur | `--target node` (`npm start`); the output's `hosts/*.md` has each host's manifest or function glue (Amplify: folder in `.amplify-hosting/compute/default/`, `static/` in `.amplify-hosting/static/`, a `deploy-manifest.json`) |
| [GitHub Pages](/docs/hosting/github-pages/), GitLab Pages | `--static`, publish `dist/` (a project site under a path prefix needs prefix-safe links) |
| [Fly.io](/docs/hosting/fly/) | `--docker`, `fly launch`, `fly deploy`, `fly secrets set WISP_SECRET=...` |
| [Railway](/docs/hosting/railway/), [Render](/docs/hosting/render/) | `--docker`, point at the repo, set `WISP_SECRET` |
| [Cloud Run](/docs/hosting/cloud-run/) | `--docker`, `gcloud run deploy --source .` |

</div>

## Edge Runtime per Route

Vercel and Netlify Edge: add `--edge` (`--target vercel --edge`, `--target netlify --edge`). The wasm app runs as a module (`opt-level = "s"`, for their size limits), and Netlify skips `static/` via `excludedPath`. Edge limits apply.

Per route (Vercel, Netlify): a route runs on the edge when its `+page.rs` or `+server.rs` says so; the rest stay on the Node function.

```rust
const RUNTIME: wisp::Runtime = wisp::Runtime::Edge; // default: Node
```

- With any Edge route, `wisp build --target vercel` (or `netlify`) writes both functions from the one app (the edge one at `opt-level = "s"`) and routes each pattern to its own: `edge.func` beside `index.func` in `config.json`, or the edge function's `path` list. `static/` stays the CDN's.
- With no Edge route the output is unchanged.
- It must be a literal, and a layout cannot set it.
- Other hosts ignore it; `--edge` puts every route there.
- The build stops, naming the route, if an Edge route uses what WebAssembly lacks (`std::fs`, `std::thread`, `std::process`, `std::net`, websockets; the Edge function of Vercel and Netlify has no sockets).

## Servers on Node, Bun and Local Deno

They read raw sockets and the app's own HTTP/1.1 parser answers (pipelining, keep-alive, chunked bodies, 413, 431 and each route's `BODY_LIMIT`, as the native server has them), with none of the host's per-request objects.

- At startup a request over loopback must be answered as the app answers it (twice, on one connection). If not, or with `WISP_NODE_HTTP=1`, they serve with `node:http`, `Bun.serve` or `Deno.serve` (one stderr line says which).
- Deno Deploy has no sockets and always uses `Deno.serve`.
- WebSockets are upgraded by the same parser; see the table below.
- A request's head and body have the native deadlines on raw connections too: one trickled past them is refused 408 when its next bytes come.
- Only the `node:http` path reads at most `WISP_BODY_LIMIT` (default 1 MB) of a body and answers 413 past it.
- The bridges that read a body with the host's own `fetch` (Workers, Deno, Netlify, Vercel Edge, Bun's `fetch` path) stop reading one byte past the route's limit and the app answers 413, so an endless body is never held in memory.
- Windows hosts pass environment names to the app upper-cased, so `wisp::env("PATH")` finds `Path`.

## AWS Lambda

Run `rustup target add x86_64-unknown-linux-musl` once. `--target lambda` writes `dist/lambda/bootstrap.zip`: the app's own static binary via Rust's lld, no C toolchain. Create the function once (runtime `provided.al2023`, `x86_64`, handler `bootstrap`) and add a Function URL (or API Gateway/ALB):

```sh
aws lambda create-function --function-name my-app --runtime provided.al2023 \
  --architectures x86_64 --handler bootstrap --role <role-arn> \
  --zip-file fileb://dist/lambda/bootstrap.zip
aws lambda update-function-code --function-name my-app --zip-file fileb://dist/lambda/bootstrap.zip
```

- Any Wisp binary answers Lambda's runtime API when `AWS_LAMBDA_RUNTIME_API` is set.
- Everything works except WebSockets (501) and streaming (a stream is sent whole).
- Saved tables go in `/tmp`, per instance: use `wisp::store` for lasting data.
- The `tower` feature with `lambda_http` also works ([embed](/docs/embed/)).

## What Works on the Edge

No threads, sockets or files.

<div class="table-wrap">

| Topic | Rule |
|---|---|
| Tasks and timers | Use `wisp::spawn` and `wisp::sleep` (they map to the host's task queue and `setTimeout`). `tokio::spawn`, `tokio::time`, sqlx, reqwest and `Response::file_in` answer 500 there; all work in the binary, Docker, Lambda. |
| Background work | Cloudflare and Netlify keep the instance alive (`waitUntil`) for started timers and fetches; Deno and Node run on; Vercel may freeze after the response, so finish first. |
| Secrets | `WISP_SECRET` as a host secret. Read others with `wisp::env("KEY")` (`std::env::var` sees nothing; no `.env`). |
| Streaming | `Response::stream` and `Response::events` are live on Cloudflare, Deno, Netlify, Vercel, Node; a leaving client fails `send`. |
| WebSockets | `Response::websocket` works where the host can hold a socket (below); 501 on Vercel, Netlify, Lambda and `tower`: use SSE. |
| Not in the edge build | `wisp::channel`, `wisp::every`, `RateLimit` (it won't compile with them): use the host's queues, cron, rate limiting. |
| Panics | A panic fails only that request (500). No `Date` header from Wisp. |

</div>

### WebSockets

The same code on every host that can hold a socket, and a 501 on the rest. `before` and the origin check run on the upgrade request as for any route. `examples/websocket` is an echo that runs on all of them.

<div class="table-wrap">

| Host | WebSockets | Made by |
|---|---|---|
| binary, Docker | yes | Wisp's server |
| `node` | yes | Wisp's parser on the raw socket; with `node:http`, its `upgrade` event |
| `bun` | yes | Wisp's parser on `Bun.listen`; with `Bun.serve`, `server.upgrade` |
| `deno` | yes | Wisp's parser on `Deno.listen`; with `Deno.serve` and Deploy, `Deno.upgradeWebSocket` |
| `cloudflare`, `pages` | yes | `WebSocketPair` |
| `vercel`, `netlify`, `lambda`, `tower` | 501 | no sockets there |

</div>

- On raw sockets the codec is the native server's: handshake, fragments, pings, the idle ping and close (`WISP_WS_IDLE`), the `BODY_LIMIT` message limit and the protocol errors.
- Where the host frames the messages (`Bun.serve`, `Deno.serve`, Deploy, Workers) it answers pings and fragments and keeps its own idle time. Wisp still refuses a message past the limit and closes with 1009. Deno's `close` takes only 1000 or codes from 3000, so there it is 4009.
- A client's close is answered on workerd, so the client sees 1000, not a cancelled request.
- A connection lives in one instance (on Cloudflare, one isolate): state shared by connections needs a Durable Object of your own or `WISP_STORE`. `wisp::channel` is native only.

### Saved Tables

`Rest` and `Table::saved` are per-instance memory unless `WISP_STORE` is set (no app code):

<div class="table-wrap">

| `WISP_STORE` | Store |
|---|---|
| `d1:DB` | Cloudflare D1 binding `DB` (`[[d1_databases]]` in wrangler.toml) |
| `deno-kv` | Deno KV (`deno-kv:<path>` file or URL) |
| `libsql://name.turso.io` | Turso or any libSQL server over HTTP, with `WISP_STORE_TOKEN` |

</div>

- Each instance reads every row at start (tables must fit in memory).
- A request's changes are one batch before the answer. A failed batch answers 500 and the next request gets a fresh instance.
- Rows: SQL table `wisp_rows (tbl, id, json)`, or `["wisp", table, id]` in Deno KV.

### Jobs

`wisp::cron` and `wisp::work` are the same code on every host. `wisp build` reads each `wisp::cron("0 3 * * *", ..)` in `src/` (the schedule must be a string literal) and writes the host's trigger:

<div class="table-wrap">

| Host | Trigger |
|---|---|
| Cloudflare | `[triggers] crons` in wrangler.toml |
| Vercel | `crons` in config.json (Hobby plan: daily only) |
| Netlify | a scheduled function |

</div>

- A trigger asks the app for `/_wisp/cron/<schedule>` with `Authorization: Bearer $CRON_SECRET`. Set it as a host secret; without it the address is 404.
- That runs the tasks of the schedule, then every queue's due jobs. An app with `work` gets a trigger each minute.
- The queue is a table, so queued jobs need `WISP_STORE`.
- Pages, Deno, Node, Bun, Lambda and Netlify `--edge` have no trigger to write: the build says so and stops. Run the binary or Docker, which run jobs themselves.

### Outbound HTTP

```rust
let mut req = wisp::Request::new("POST", "https://api.example.com/rows");
req.header(
    "authorization",
    &format!("Bearer {}", wisp::env("API_KEY").unwrap_or_default()),
);
req.body = json.into_bytes();
let reply = wisp::edge::fetch(req).await?;
```
