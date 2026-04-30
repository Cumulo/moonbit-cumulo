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
  #|   const devPorts = ["5173", "5174", "5175", "5176"];
  #|   if (devPorts.includes(window.location.port)) {
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
  let pending_socket : Ref[WebSocket?] = Ref::new(None)
  let socket = connect_socket(
    socket_url(),
    fn() {
      browser_log("ws opened")
      // Only expose the socket for sending after the connection is open
      socket_ref.val = pending_socket.val
      let (new_store, _) = app.store.val.update(SocketOpened)
      app.store.val = new_store
      @respo.mark_need_rerender()
    },
    fn(text) {
      try {
        let parsed = @json.parse(text)
        let payload : @shared.ServerEvent = @json.from_json(parsed)
        match payload {
          Snapshot(seq~, store~) => {
            browser_log(
              "recv Snapshot seq=\{seq} logged_in=\{store.logged_in} bulletins=\{store.bulletins.length()} members=\{store.member_count} viewers=\{store.viewer_count}",
            )
            let (new_store, _) = app.store.val.update(ReceiveSnapshot(store))
            app.store.val = new_store
            @respo.mark_need_rerender()
            browser_log("store updated -> render triggered (Snapshot)")
          }
          Delta(seq~, patches~) => {
            browser_log("recv Delta seq=\{seq} patches=\{patches.length()}")
            let before = app.store.val.remote
            let (new_store, _) = app.store.val.update(ReceiveDelta(patches))
            let after = new_store.remote
            app.store.val = new_store
            @respo.mark_need_rerender()
            browser_log(
              "store updated -> render triggered (Delta) logged_in=\{after.logged_in} bulletins=\{after.bulletins.length()} viewers=\{after.viewer_count} changed=\{before != after}",
            )
          }
        }
      } catch {
        _ => browser_error("failed to parse server event: \{text[:120]}")
      }
    },
    fn() {
      browser_warn("ws closed")
      socket_ref.val = None
      pending_socket.val = None
      let (new_store, _) = app.store.val.update(SocketClosed)
      app.store.val = new_store
      @respo.mark_need_rerender()
    },
  )
  pending_socket.val = Some(socket)
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
          let (new_store, _) = app.store.val.update(ReconnectSocket)
          app.store.val = new_store
          connect_runtime(app, socket_ref)
        }
        _ => {
          let (new_store, maybe_op) = app.store.val.update(op)
          app.store.val = new_store
          match maybe_op {
            Some(client_op) => {
              browser_log(
                "action -> server op: \{client_op.to_json().stringify()}",
              )
              send_client_op(socket_ref, client_op)
            }
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
