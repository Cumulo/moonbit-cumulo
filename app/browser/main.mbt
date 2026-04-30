///|
pub(all) enum ConnectionState {
  Connecting
  Open
  Closed
} derive(Eq, Debug)

///|
pub(all) enum AuthMode {
  Login
  SignUp
} derive(Eq, Debug)

///|
pub(all) struct UiState {
  auth_mode : AuthMode
  username : String
  password : String
  bulletin_draft : String
  connection : ConnectionState
} derive(Eq, Debug)

///|
#external
type WebSocket

///|
pub(all) struct BrowserApp {
  mut remote : @shared.ClientView
  mut ui : UiState
  mut socket : WebSocket?
}

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

///|
extern "js" fn set_root_html(id : String, html : String) -> Unit =
  #| (id, html) => {
  #|   const node = document.getElementById(id);
  #|   if (node) {
  #|     node.innerHTML = html;
  #|   }
  #| }

///|
extern "js" fn escape_html(text : String) -> String =
  #| (text) => String(text)
  #|   .replace(/&/g, "&amp;")
  #|   .replace(/</g, "&lt;")
  #|   .replace(/>/g, "&gt;")
  #|   .replace(/"/g, "&quot;")

///|
extern "js" fn install_dom_bridge(
  root_id : String,
  dispatch : (String, String) -> Unit,
) -> Unit =
  #| (rootId, dispatch) => {
  #|   const root = document.getElementById(rootId);
  #|   if (!root || root.__moonCumuloBound) {
  #|     return;
  #|   }
  #|   root.__moonCumuloBound = true;
  #|   root.addEventListener("click", (event) => {
  #|     const target = event.target instanceof Element ? event.target.closest("[data-action]") : null;
  #|     if (!target) {
  #|       return;
  #|     }
  #|     event.preventDefault();
  #|     dispatch(target.getAttribute("data-action") || "", target.getAttribute("data-value") || "");
  #|   });
  #|   root.addEventListener("input", (event) => {
  #|     const target = event.target;
  #|     if (!target || typeof target.getAttribute !== "function") {
  #|       return;
  #|     }
  #|     const model = target.getAttribute("data-model");
  #|     if (!model) {
  #|       return;
  #|     }
  #|     dispatch(`input:${model}`, String(target.value ?? ""));
  #|   });
  #|   root.addEventListener("submit", (event) => {
  #|     event.preventDefault();
  #|   });
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
fn join_html(parts : Array[String]) -> String {
  let mut out = ""
  for part in parts {
    out = out + part
  }
  out
}

///|
fn nav_button(label : String, action : String, active : Bool) -> String {
  let klass = if active { "nav-link is-active" } else { "nav-link" }
  "<button type=\"button\" class=\"\{klass}\" data-action=\"\{action}\">\{label}</button>"
}

///|
fn render_messages(messages : Array[@shared.FlashMessage]) -> String {
  let items = Array::new(capacity=messages.length())
  for message in messages {
    let kind = match message.kind {
      Info => "toast is-info"
      Error => "toast is-error"
    }
    let title = match message.kind {
      Info => "Info"
      Error => "Error"
    }
    let escaped_title = escape_html(title)
    let escaped_text = escape_html(message.text)
    let message_id = escape_html(message.id)
    items.push(
      "<div class=\"\{kind}\"><div><strong>\{escaped_title}</strong><p>\{escaped_text}</p></div><button type=\"button\" class=\"ghost\" data-action=\"message:clear\" data-value=\"\{message_id}\">Dismiss</button></div>",
    )
  }
  join_html(items)
}

///|
fn render_members(members : Array[@shared.MemberView]) -> String {
  let items = Array::new(capacity=members.length())
  for person in members {
    let name = escape_html(person.name)
    let id = escape_html(person.id)
    items.push(
      "<article class=\"member-card\"><h3>\{name}</h3><p>id: \{id}</p></article>",
    )
  }
  join_html(items)
}

///|
fn render_bulletins(bulletins : Array[@shared.BulletinEntry]) -> String {
  if bulletins.length() == 0 {
    return "<article class=\"bulletin-card is-empty\"><p>No bulletins yet.</p></article>"
  }
  let items = Array::new(capacity=bulletins.length())
  for bulletin in bulletins {
    let author = escape_html(bulletin.author)
    let text = escape_html(bulletin.text)
    items.push(
      "<article class=\"bulletin-card\"><p class=\"bulletin-meta\">\{author}</p><p class=\"bulletin-text\">\{text}</p></article>",
    )
  }
  join_html(items)
}

///|
fn connection_label(state : ConnectionState) -> String {
  match state {
    Connecting => "Connecting"
    Open => "Live"
    Closed => "Closed"
  }
}

///|
fn render_auth_panel(remote : @shared.ClientView, ui : UiState) -> String {
  match remote.current_user {
    Some(user) => {
      let name = escape_html(user.name)
      let session_id = escape_html(remote.session_id)
      let connection = connection_label(ui.connection)
      "<section class=\"panel auth-panel\"><p class=\"eyebrow\">Current session</p><h2>\{name}</h2><p>session: \{session_id}</p><p>connection: \{connection}</p><div class=\"auth-actions\"><button type=\"button\" class=\"solid\" data-action=\"route:members\">Browse members</button><button type=\"button\" class=\"ghost\" data-action=\"auth:logout\">Log out</button></div></section>"
    }
    None => {
      let login_active = ui.auth_mode == Login
      let login_klass = if login_active { "tab is-active" } else { "tab" }
      let signup_klass = if login_active { "tab" } else { "tab is-active" }
      let submit_label = if login_active { "Log in" } else { "Create account" }
      let submit_action = if login_active {
        "auth:login"
      } else {
        "auth:signup"
      }
      let username = escape_html(ui.username)
      let password = escape_html(ui.password)
      "<section class=\"panel auth-panel\"><p class=\"eyebrow\">Account</p><div class=\"tabs\"><button type=\"button\" class=\"\{login_klass}\" data-action=\"mode:login\">Login</button><button type=\"button\" class=\"\{signup_klass}\" data-action=\"mode:signup\">Sign up</button></div><label class=\"field\"><span>Username</span><input data-model=\"username\" value=\"\{username}\" placeholder=\"demo\" /></label><label class=\"field\"><span>Password</span><input type=\"password\" data-model=\"password\" value=\"\{password}\" placeholder=\"demo\" /></label><div class=\"auth-actions\"><button type=\"button\" class=\"solid\" data-action=\"\{submit_action}\">\{submit_label}</button><button type=\"button\" class=\"ghost\" data-action=\"fill:demo\">Use demo/demo</button></div></section>"
    }
  }
}

///|
fn render_route(remote : @shared.ClientView, ui : UiState) -> String {
  match remote.route {
    Home => {
      let bulletins = render_bulletins(remote.bulletins)
      let draft = escape_html(ui.bulletin_draft)
      let composer = if remote.logged_in {
        "<div class=\"bulletin-composer\"><label class=\"field\"><span>Post an update for every connected page</span><input data-model=\"bulletin\" value=\"\{draft}\" placeholder=\"Ship note, deployment update, etc.\" /></label><button type=\"button\" class=\"solid\" data-action=\"bulletin:post\">Post bulletin</button></div>"
      } else {
        "<p class=\"board-note\">Log in to post on the shared bulletin board. Other tabs will receive the update as a delta.</p>"
      }
      "<section class=\"panel content-panel\"><p class=\"eyebrow\">Home</p><h2>How this mirrors Cumulo</h2><div class=\"feature-grid\"><article><h3>Authoritative server</h3><p>The server keeps the full AppDb and applies a pure updater for every client operation.</p></article><article><h3>Session twig</h3><p>Each WebSocket client receives a filtered ClientView, not the raw database.</p></article><article><h3>Diff over WebSocket</h3><p>After the first snapshot, later changes go out as structural patches built by diff_value.</p></article></div></section><section class=\"panel content-panel\"><div class=\"board-header\"><div><p class=\"eyebrow\">Bulletin board</p><h2>Shared demo state</h2></div><span class=\"board-count\">\{remote.bulletins.length()} posts</span></div><p class=\"board-note\">Use this to verify that one page can mutate shared state and every other page patches into the new projection.</p>\{composer}<div class=\"bulletin-list\">\{bulletins}</div></section>"
    }
    Members => {
      let members_html = render_members(remote.members)
      "<section class=\"panel content-panel\"><p class=\"eyebrow\">Members</p><h2>Known users</h2><div class=\"member-grid\">\{members_html}</div></section>"
    }
  }
}

///|
fn render_page(remote : @shared.ClientView, ui : UiState) -> String {
  let connection_klass = match ui.connection {
    Open => "status-badge is-live"
    Connecting => "status-badge is-connecting"
    Closed => "status-badge is-closed"
  }
  let user_name = match remote.current_user {
    Some(user) => user.name
    None => "guest"
  }
  let reconnect = if ui.connection == Closed {
    "<button type=\"button\" class=\"ghost\" data-action=\"socket:reconnect\">Reconnect</button>"
  } else {
    ""
  }
  let welcome = escape_html(remote.welcome)
  let connection = connection_label(ui.connection)
  let nav_home = nav_button("Home", "route:home", remote.route == Home)
  let nav_members = nav_button(
    "Members",
    "route:members",
    remote.route == Members,
  )
  let viewer = escape_html(user_name)
  let auth_panel = render_auth_panel(remote, ui)
  let messages_html = render_messages(remote.messages)
  let route_html = render_route(remote, ui)
  let accent = remote.accent
  "<div class=\"shell\" style=\"--accent:\{accent};\"><header class=\"hero\"><div><p class=\"eyebrow\">MoonBit + Cumulo</p><h1>Realtime fullstack patch sync</h1><p class=\"lead\">\{welcome}</p></div><div class=\"hero-meta\"><span class=\"\{connection_klass}\">\{connection}</span><div class=\"hero-stats\"><strong>\{remote.viewer_count}</strong><span>viewers</span></div><div class=\"hero-stats\"><strong>\{remote.member_count}</strong><span>users</span></div>\{reconnect}</div></header><nav class=\"nav\">\{nav_home}\{nav_members}<span class=\"nav-user\">viewer: \{viewer}</span></nav><section class=\"layout\"><aside class=\"sidebar\">\{auth_panel}<section class=\"panel tips\"><p class=\"eyebrow\">Transport</p><p>Snapshot on connect. Delta patches afterwards. The browser applies patches to a typed ClientView.</p></section></aside><main class=\"main\">\{messages_html}\{route_html}</main></section></div>"
}

///|
pub fn BrowserApp::new() -> BrowserApp {
  {
    remote: @shared.empty_view("pending"),
    ui: {
      auth_mode: Login,
      username: "",
      password: "",
      bulletin_draft: "",
      connection: Connecting,
    },
    socket: None,
  }
}

///|
fn BrowserApp::render(self : BrowserApp) -> Unit {
  set_root_html("app", render_page(self.remote, self.ui))
}

///|
fn BrowserApp::set_connection(
  self : BrowserApp,
  state : ConnectionState,
) -> Unit {
  self.ui = { ..self.ui, connection: state }
}

///|
fn BrowserApp::send_op(self : BrowserApp, op : @shared.ClientOp) -> Unit {
  match self.socket {
    Some(socket) => socket_send(socket, op.to_json().stringify())
    None => browser_log("socket is not connected")
  }
}

///|
fn BrowserApp::handle_server_event(self : BrowserApp, text : String) -> Unit {
  try {
    let parsed = @json.parse(text)
    let payload : @shared.ServerEvent = @json.from_json(parsed)
    match payload {
      Snapshot(seq~, store~) => {
        ignore(seq)
        self.remote = store
      }
      Delta(seq~, patches~) => {
        ignore(seq)
        self.remote = @recollect.apply_to_value(self.remote, patches)
      }
    }
    self.render()
  } catch {
    _ => browser_log("failed to parse server event")
  }
}

///|
fn BrowserApp::connect(self : BrowserApp) -> Unit {
  if self.socket is Some(existing) {
    socket_close(existing)
  }
  self.set_connection(Connecting)
  self.render()
  let socket = connect_socket(
    socket_url(),
    fn() {
      self.set_connection(Open)
      self.render()
    },
    text => self.handle_server_event(text),
    fn() {
      self.socket = None
      self.set_connection(Closed)
      self.render()
    },
  )
  self.socket = Some(socket)
}

///|
fn BrowserApp::apply_dom_event(
  self : BrowserApp,
  action : String,
  value : String,
) -> Unit {
  match action {
    "input:username" => self.ui = { ..self.ui, username: value }
    "input:password" => self.ui = { ..self.ui, password: value }
    "input:bulletin" => self.ui = { ..self.ui, bulletin_draft: value }
    "mode:login" => self.ui = { ..self.ui, auth_mode: Login }
    "mode:signup" => self.ui = { ..self.ui, auth_mode: SignUp }
    "fill:demo" =>
      self.ui = {
        ..self.ui,
        username: "demo",
        password: "demo",
        auth_mode: Login,
      }
    "route:home" => self.send_op(RouteChange(route=Home))
    "route:members" => self.send_op(RouteChange(route=Members))
    "auth:login" =>
      self.send_op(
        UserLogIn(username=self.ui.username, password=self.ui.password),
      )
    "auth:signup" =>
      self.send_op(
        UserSignUp(username=self.ui.username, password=self.ui.password),
      )
    "auth:logout" => self.send_op(UserLogOut)
    "bulletin:post" => {
      self.send_op(BulletinPost(text=self.ui.bulletin_draft))
      self.ui = { ..self.ui, bulletin_draft: "" }
    }
    "socket:reconnect" => {
      self.connect()
      return
    }
    "message:clear" => self.send_op(SessionRemoveMessage(id=value))
    _ => ()
  }
  self.render()
}

///|
pub fn run_app() -> Unit {
  let app = BrowserApp::new()
  app.render()
  install_dom_bridge("app", (action, value) => {
    app.apply_dom_event(action, value)
  })
  app.connect()
}

///|
fn main {
  run_app()
}
