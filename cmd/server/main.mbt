///|
#external
type NodeRuntime

///|
extern "js" fn server_log(text : String) -> Unit =
  #| (text) => console.log(text)

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
  mut store : @app_server.FullstackServer
  mut next_op_id : Int
}

///|
pub fn RuntimeApp::new() -> RuntimeApp {
  {
    store: @app_server.FullstackServer::new(@shared.initial_db()),
    next_op_id: 0,
  }
}

///|
fn RuntimeApp::flush(
  _self : RuntimeApp,
  events : Array[@app_server.SessionEvent],
) -> Unit {
  for event in events {
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
  server_log("connect \{sid}")
  self.flush(self.store.connect(sid))
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
    self.flush(self.store.dispatch(sid, op, op_id))
  } catch {
    _ => server_log("invalid client payload from \{sid}")
  }
}

///|
fn RuntimeApp::handle_close(self : RuntimeApp, sid : String) -> Unit {
  server_log("disconnect \{sid}")
  self.flush(self.store.disconnect(sid))
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
