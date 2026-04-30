///|
#external
type WebSocket

///|
extern "js" fn browser_log(text : String) -> Unit =
  #| (text) => console.log("[cumulo] " + text)

///|
extern "js" fn browser_warn(text : String) -> Unit =
  #| (text) => console.warn("[cumulo] " + text)

///|
extern "js" fn browser_error(text : String) -> Unit =
  #| (text) => console.error("[cumulo] " + text)

///|
extern "js" fn socket_url() -> String =
  #| () => {
  #|   const protocol = window.location.protocol === "https:" ? "wss" : "ws";
  #|   if (window.location.port === "5173") {
  #|     return `${protocol}://${window.location.hostname}:5022/ws`;
  #|   }
  #|   return `${protocol}://${window.location.host}/ws`;
  #| }

///|
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
fn send_client_op(socket_ref : Ref[WebSocket?], op : @shared.ClientOp) -> Unit {
  match socket_ref.val {
    Some(socket) => {
      let text = op.to_json().stringify()
      browser_log("send op: \{text}")
      socket_send(socket, text)
    }
    None => browser_warn("send op skipped — socket not connected")
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
      browser_log("ws opened")
      ignore(app.store.val.update(SocketOpened))
      app.store.val = { ..app.store.val }
      @respo.mark_need_rerender()
    },
    fn(text) {
      try {
        let parsed = @json.parse(text)
        let payload : @shared.ServerEvent = @json.from_json(parsed)
        match payload {
          Snapshot(seq~, store~) => {
            browser_log(
              "recv Snapshot seq=\{seq} logged_in=\{store.logged_in} bulletins=\{store.bulletins.length()}",
            )
            ignore(app.store.val.update(ReceiveSnapshot(store)))
            app.store.val = { ..app.store.val }
            @respo.mark_need_rerender()
          }
          Delta(seq~, patches~) => {
            browser_log("recv Delta seq=\{seq} patches=\{patches.length()}")
            ignore(app.store.val.update(ReceiveDelta(patches)))
            app.store.val = { ..app.store.val }
            @respo.mark_need_rerender()
          }
        }
      } catch {
        _ => browser_error("failed to parse server event: \{text[:120]}")
      }
    },
    fn() {
      browser_warn("ws closed")
      socket_ref.val = None
      ignore(app.store.val.update(SocketClosed))
      app.store.val = { ..app.store.val }
      @respo.mark_need_rerender()
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
          browser_log("action: ReconnectSocket")
          ignore(app.store.val.update(ReconnectSocket))
          app.store.val = { ..app.store.val }
          connect_runtime(app, socket_ref)
        }
        _ => {
          let maybe_op = app.store.val.update(op)
          app.store.val = { ..app.store.val }
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
