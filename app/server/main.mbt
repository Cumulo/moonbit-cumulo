///|
#external
type NodeRuntime

///|
extern "js" fn monitor_log(text : String) -> Unit =
  #| (text) => {
  #|   const fs = require("fs");
  #|   const path = require("path");
  #|   const dir = path.join(process.cwd(), ".runtime-monitor");
  #|   if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  #|   const file = path.join(dir, "server.log");
  #|   const line = new Date().toISOString() + "  " + text + "\n";
  #|   fs.appendFileSync(file, line);
  #|   console.log("[server] " + text);
  #| }

///|
extern "js" fn send_to_client(sid : String, text : String) -> Unit =
  #| (sid, text) => {
  #|   const clients = globalThis.__moonCumuloClients;
  #|   if (!clients) {
  #|     return;
  #|   }
  #|   const socket = clients.get(sid);
  #|   if (!socket || socket.readyState !== 1) {
  #|     return;
  #|   }
  #|   socket.send(text);
  #| }

///|
extern "js" fn start_server(
  on_open : (String) -> Unit,
  on_message : (String, String) -> Unit,
  on_close : (String) -> Unit,
) -> NodeRuntime =
  #| (onOpen, onMessage, onClose) => {
  #|   const crypto = require("crypto");
  #|   const { WebSocketServer } = require("ws");
  #|   const clients = new Map();
  #|   globalThis.__moonCumuloClients = clients;
  #|   const wss = new WebSocketServer({ port: 5022, path: "/ws" });
  #|   wss.on("connection", (socket) => {
  #|     const sid = crypto.randomUUID();
  #|     clients.set(sid, socket);
  #|     onOpen(sid);
  #|     socket.on("message", (buffer) => onMessage(sid, String(buffer)));
  #|     socket.on("close", () => {
  #|       clients.delete(sid);
  #|       onClose(sid);
  #|     });
  #|   });
  #|   wss.on("listening", () => {
  #|     console.log("MoonBit Cumulo WebSocket backend listening on ws://localhost:5022/ws");
  #|   });
  #|   return { wss };
  #| }

///|
pub(all) struct RuntimeApp {
  mut store : FullstackServer
  mut next_op_id : Int
}

///|
pub fn RuntimeApp::new() -> RuntimeApp {
  { store: FullstackServer::new(@shared.initial_db()), next_op_id: 0 }
}

///|
fn RuntimeApp::flush(_self : RuntimeApp, events : Array[SessionEvent]) -> Unit {
  for event in events {
    let short_sid = event.sid[:8]
    match event.payload {
      Snapshot(seq~, store~) =>
        monitor_log(
          "flush -> \{short_sid}… Snapshot seq=\{seq} logged_in=\{store.logged_in} bulletins=\{store.bulletins.length()} members=\{store.member_count} viewers=\{store.viewer_count}",
        )
      Delta(seq~, patches~) => {
        let first = if patches.length() > 0 {
          patches[0].to_json().stringify()
        } else {
          ""
        }
        monitor_log(
          "flush -> \{short_sid}… Delta seq=\{seq} patches=\{patches.length()} first=\{first}",
        )
      }
    }
    send_to_client(event.sid, event.payload.to_json().stringify())
  }
}

///|
fn RuntimeApp::next_id(self : RuntimeApp) -> String {
  self.next_op_id = self.next_op_id + 1
  "op-\{self.next_op_id}"
}

///|
fn RuntimeApp::handle_open(self : RuntimeApp, sid : String) -> Unit {
  monitor_log("connect \{sid}")
  let events = self.store.connect(sid)
  monitor_log(
    "connect sync -> \{events.length()} events for \{self.store.db.sessions.length()} sessions",
  )
  self.flush(events)
}

///|
fn RuntimeApp::handle_message(
  self : RuntimeApp,
  sid : String,
  text : String,
) -> Unit {
  try {
    let parsed = @json.parse(text)
    let op : @shared.ClientOp = @json.from_json(parsed)
    let op_id = self.next_id()
    monitor_log("op \{op_id} from \{sid}: \{op.to_json().stringify()}")
    let events = self.store.dispatch(sid, op, op_id)
    let db = self.store.db()
    monitor_log(
      "op \{op_id} dispatched -> \{events.length()} events | db: sessions=\{db.sessions.length()} bulletins=\{db.bulletins.length()} users=\{db.users.length()}",
    )
    self.flush(events)
  } catch {
    _ => monitor_log("invalid client payload from \{sid}: \{text}")
  }
}

///|
fn RuntimeApp::handle_close(self : RuntimeApp, sid : String) -> Unit {
  monitor_log("disconnect \{sid}")
  let events = self.store.disconnect(sid)
  monitor_log(
    "disconnect sync -> \{events.length()} events for \{self.store.db.sessions.length()} remaining sessions",
  )
  self.flush(events)
}

///|
fn main {
  let app = RuntimeApp::new()
  ignore(
    start_server(
      sid => app.handle_open(sid),
      (sid, text) => app.handle_message(sid, text),
      sid => app.handle_close(sid),
    ),
  )
}
