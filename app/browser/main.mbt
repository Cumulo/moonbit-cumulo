///|
#external
type WebSocket

///|
extern "js" fn browser_log(text : String) -> Unit =
  #| (text) => console.log(text)

///|
extern "js" fn socket_url() -> String =
  #| () => {
  #|   const protocol = window.location.protocol === "https:" ? "wss" : "ws";
  #|   if (window.location.port === "5173") {
  #|     return `${protocol}://${window.location.hostname}:5022/ws`;
  #|   }
  #|   return `${protocol}://${window.location.host}/ws`;
  #| }

extern "js" fn connect_socket(
  url : String,
  on_open : () -> Unit,
  on_message : (String) -> Unit,
  on_close : () -> Unit,
) -> WebSocket =
  #| (url, onOpen, onMessage, onClose) => {
  #|   const socket = new WebSocket(url);
  #|   socket.addEventListener("open", () => onOpen());
  #|   socket.addEventListener("message", (event) => onMessage(String(event.data ?? "")));
  #|   socket.addEventListener("close", () => onClose());
  #|   return socket;
  #| }

///|
extern "js" fn socket_send(socket : WebSocket, text : String) -> Unit =
  #| (socket, text) => socket.send(text)

///|
extern "js" fn socket_close(socket : WebSocket) -> Unit =
  #| (socket) => socket.close()

///|
fn send_client_op(
  socket_ref : Ref[WebSocket?],
  op : @shared.ClientOp,
) -> Unit {
  match socket_ref.val {
    Some(socket) => socket_send(socket, op.to_json().stringify())
    None => browser_log("socket is not connected")
  }
}

///|
fn connect_runtime(
  app : @respo.RespoApp[Store],
  socket_ref : Ref[WebSocket?],
) -> Unit {
  match socket_ref.val {
    Some(existing) => {
      socket_close(existing)
      socket_ref.val = None
    }
    None => ()
  }
  let socket = connect_socket(
    socket_url(),
    fn() {
      ignore(app.store.val.update(SocketOpened))
    },
    fn(text) {
      try {
        let parsed = @json.parse(text)
        let payload : @shared.ServerEvent = @json.from_json(parsed)
        match payload {
          Snapshot(seq~, store~) => {
            ignore(seq)
            ignore(app.store.val.update(ReceiveSnapshot(store)))
          }
          Delta(seq~, patches~) => {
            ignore(seq)
            ignore(app.store.val.update(ReceiveDelta(patches)))
          }
        }
      } catch {
        _ => browser_log("failed to parse server event")
      }
    },
    fn() {
      socket_ref.val = None
      ignore(app.store.val.update(SocketClosed))
    },
  )
  socket_ref.val = Some(socket)
}

///|
fn main {
  let window = @dom_ffi.window()
  if window.document().query_selector("#app") is Some(mount_target) {
    let mount_target = mount_target.reinterpret_as_node()
    let app : @respo.RespoApp[Store] = {
      store: Ref::new(Store::default()),
      mount_target,
      storage_key: "moon-cumulo-browser",
    }
    let socket_ref : Ref[WebSocket?] = Ref::new(None)
    app.render_loop(() => view(app.store.val), op => {
      match op {
        ReconnectSocket => {
          ignore(app.store.val.update(ReconnectSocket))
          connect_runtime(app, socket_ref)
        }
        _ => {
          let maybe_op = app.store.val.update(op)
          match maybe_op {
            Some(client_op) => send_client_op(socket_ref, client_op)
            None => ()
          }
        }
      }
    })
    connect_runtime(app, socket_ref)
  } else {
    browser_log("No mount target found")
  }
}
