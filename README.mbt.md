# tiye/cumulo

MoonBit implementation of a Cumulo-style diff transport.

The structural diff and patch engine now lives in `tiye/cumulo/recollect`. The root `tiye/cumulo` package keeps the sample state and the demo-facing types used by the examples in this repository.

This repo also contains a full end-to-end demo with:

- authoritative server state
- per-session twig projection
- WebSocket snapshot and delta sync
- browser client applying structural patches

## Repository layout

Core packages:

- `recollect`: standalone structural diff/patch engine
- `tiye/cumulo`: sample types and compatibility helpers around `recollect`

Mainline demo packages:

- `app/shared`: domain model, client protocol, pure updater, twig projection
- `app/server`: authoritative store plus the Node WebSocket runtime entry
- `app/browser`: browser UI, WebSocket client runtime, and browser JS entry

Example packages:

- `examples/todo-sync/shared`: sync protocol and pure reducer for the typed todo example
- `examples/todo-sync/server`: in-memory authoritative store for the example
- `examples/todo-sync/client`: client-side patch application for the example
- `examples/todo-sync`: runnable example entry with `moon run ./examples/todo-sync`

Package-level API notes for `recollect` live in `recollect/README.md`.

## Run

Install the Node runtime dependencies and start the app:

```bash
npm install
npm start
```

Then open `http://127.0.0.1:5173`.

Notes:

- Vite serves the page shell on port `5173`.
- The MoonBit backend only owns the WebSocket server on port `5022`.
- When the browser is served from Vite, the client connects directly to `ws://127.0.0.1:5022/ws`.
- `localhost:5173` usually works too, but `127.0.0.1` avoids local IPv6 collisions if another dev server is already bound on `::1:5173`.

Quick smoke login:

- username: `demo`
- password: `demo`

## Useful commands

```bash
moon test ./recollect
moon test ./app/shared ./app/server
moon test ./examples/todo-sync/client
moon run ./examples/todo-sync
npm run build
```

## Protocol shape

Derived MoonBit enum JSON uses array form for payload-bearing constructors.

Examples:

```json
["UserLogIn", {"username": "demo", "password": "demo"}]
["RouteChange", {"route": "Members"}]
```

Server events are also enum arrays, for example:

```json
["Snapshot", {"seq": 1, "store": {"session_id": "..."}}]
["Delta", {"seq": 2, "patches": [["Set", {"path": [["Field", "logged_in"]], "value": true}]]}]
```

## Publishing recollect later

`recollect` is intentionally kept as a leaf package:

- its public API lives under `recollect/`
- its package-level docs live in `recollect/README.md`
- it only depends on `moonbitlang/core/json`

That means the future publishing paths stay simple:

- move `recollect/` into its own repository and make it the new MoonBit module root
- or keep this repo as the integration/demo repo and promote `recollect/` into a dedicated MoonBit workspace/module that is published on its own

The current repo shape already keeps that extraction mechanical. No extra workspace-specific publishing metadata is required yet.

## Verified

The current implementation was validated with:

- `npm run build`
- HTTP shell served from `http://127.0.0.1:5173`
- WebSocket backend served from `ws://localhost:5022/ws`
- initial WebSocket `Snapshot`
- login operation returning a `Delta`
- multi-page bulletin sync confirmed between two browser tabs
