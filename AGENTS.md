# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod.json` file listing module
  metadata.

- The current mainline layout is:
  - `recollect/`: standalone diff/patch package intended to stay easy to split
  - `app/shared`, `app/server`, `app/browser`: fullstack demo packages, with browser/server entrypoints kept under `app/*`
  - `examples/todo-sync/*`: smaller typed sync walkthrough kept out of the mainline path

- `README.md` is a symlink to `README.mbt.md`. Update `README.mbt.md` when changing the root package README.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In this repo, do not run `moon info` blindly across every package. The JS entry packages use `extern "js"`, and a full-module `moon info` run will fail under the default wasm-gc canonical backend.

- Prefer targeted `moon info` runs on non-JS packages such as:
  - `./recollect`
  - `./app/shared`
  - `./app/server`
  - `./examples/todo-sync/shared`
  - `./examples/todo-sync/server`
  - `./examples/todo-sync/client`

- After targeted interface updates, run `moon fmt`. Check the diffs of `.mbti` files to see if the changes are expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- This project uses **yarn** (not npm). Always use `yarn` to install dependencies and run scripts.

- Useful validation commands in this repo:
  - `moon test ./recollect`
  - `moon test ./app/shared ./app/server`
  - `moon test ./examples/todo-sync/client`
  - `moon run ./examples/todo-sync`
  - `yarn build`

- Runtime layout:
  - Vite serves the page shell on port `5173`
  - the MoonBit backend serves only WebSocket traffic on port `5022`
  - the browser bundle is generated from `app/browser` into `public/static/client.js` by `scripts/sync-client.cjs`

- Treat `public/static/*.js` and `dist/` as generated outputs. Regenerate them instead of editing them by hand.

- When touching `recollect`, keep it dependency-light and independent from demo packages so it can be moved into its own module or workspace later without code surgery.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. Use snapshot tests to record current
  behavior. For solid, well-defined results (e.g. scientific computations),
  prefer assertion tests. You can use `moon coverage analyze > uncovered.log` to
  see which parts of your code are not covered by tests.

## Runtime Monitoring (sync chain logs)

The server writes structured logs to `.runtime-monitor/server.log` automatically when running.
The browser prints logs to the DevTools console under the `[cumulo]` prefix.

### Backend logs

Start the server normally:

```bash
yarn node _build/js/debug/build/app/server/server.js
```

Logs are appended to `.runtime-monitor/server.log` (directory is created on first use, excluded from git).
Each line is `ISO-timestamp  <message>`. Tail in real-time:

```bash
tail -f .runtime-monitor/server.log
```

Key log lines to look for:

| Pattern                                   | Meaning                            |
| ----------------------------------------- | ---------------------------------- |
| `connect <sid>`                           | Client WebSocket opened            |
| `connect sync -> N events for M sessions` | Snapshot dispatched after connect  |
| `op <id> from <sid>: {...}`               | Client operation received          |
| `op <id> dispatched -> N events`          | How many clients were notified     |
| `flush -> <sid> Snapshot`                 | Full state sent to a client        |
| `flush -> <sid> Delta(N patches)`         | Incremental patch sent to a client |
| `disconnect <sid>`                        | Client WebSocket closed            |
| `invalid client payload from <sid>:`      | Malformed message received         |

### Browser console logs

Open DevTools → Console and filter by `[cumulo]`.

| Message                                      | Meaning                       |
| -------------------------------------------- | ----------------------------- |
| `[cumulo] ws opened`                         | WebSocket connected to server |
| `[cumulo] recv Snapshot seq=N ...`           | Full state snapshot received  |
| `[cumulo] recv Delta seq=N patches=N`        | Incremental patch received    |
| `[cumulo] send op: {...}`                    | User action sent to server    |
| `[cumulo] ws closed`                         | WebSocket disconnected        |
| `[cumulo] failed to parse server event: ...` | Protocol parse error          |

Capture with chrome-devtools CLI:

```bash
# List all cumulo messages
chrome-devtools list_console_messages | grep '\[cumulo\]'

# List only errors
chrome-devtools list_console_messages --types error

# Get full message by id
chrome-devtools get_console_message <msgid>
```

### Typical healthy sync sequence

1. Server: `connect <sid>` → `connect sync -> 1 events` → `flush -> <sid> Snapshot`
2. Browser: `ws opened` → `recv Snapshot seq=0 logged_in=false`
3. User logs in → Browser: `send op: {"Login":...}` → Server: `op 1 from <sid>: ...` → `flush -> <sid> Delta(N patches)`
4. Browser: `recv Delta seq=1 patches=N`

### After editing server or browser source

```bash
# Rebuild server
moon build --target js ./app/server

# Rebuild browser + sync static file
moon build --target js ./app/browser && node scripts/sync-client.cjs

# Restart server
kill $(pgrep -f 'server.js') 2>/dev/null; yarn node _build/js/debug/build/app/server/server.js &

# Refresh browser
chrome-devtools navigate_page --url http://localhost:5173/ --ignoreCache
```
