///|
enum ConnectionState {
  Connecting
  Open
  Closed
} derive(Eq, Debug)

///|
enum AuthMode {
  Login
  SignUp
} derive(Eq, Debug)

///|
struct UiState {
  auth_mode : AuthMode
  username : String
  password : String
  bulletin_draft : String
  connection : ConnectionState
} derive(Eq, Debug)

///|
impl Default for UiState with default() -> UiState {
  {
    auth_mode: Login,
    username: "",
    password: "",
    bulletin_draft: "",
    connection: Connecting,
  }
}

///|
struct Store {
  mut remote : @shared.ClientView
  mut ui : UiState
} derive(Eq, Debug)

///|
impl Default for Store with default() -> Store {
  { remote: @shared.empty_view("pending"), ui: UiState::default() }
}

///|
enum ActionOp {
  UpdateUsername(String)
  UpdatePassword(String)
  UpdateBulletinDraft(String)
  SetAuthMode(AuthMode)
  FillDemo
  RouteHome
  RouteMembers
  LogIn
  SignUp
  LogOut
  PostBulletin
  ReconnectSocket
  ClearMessage(String)
  SocketOpened
  SocketClosed
  ReceiveSnapshot(@shared.ClientView)
  ReceiveDelta(Array[@recollect.PatchOp])
}

///|
fn Store::update(self : Store, op : ActionOp) -> @shared.ClientOp? {
  match op {
    UpdateUsername(value) => {
      self.ui = { ..self.ui, username: value }
      None
    }
    UpdatePassword(value) => {
      self.ui = { ..self.ui, password: value }
      None
    }
    UpdateBulletinDraft(value) => {
      self.ui = { ..self.ui, bulletin_draft: value }
      None
    }
    SetAuthMode(mode) => {
      self.ui = { ..self.ui, auth_mode: mode }
      None
    }
    FillDemo => {
      self.ui = {
        ..self.ui,
        auth_mode: Login,
        username: "demo",
        password: "demo",
      }
      None
    }
    RouteHome => Some(RouteChange(route=Home))
    RouteMembers => Some(RouteChange(route=Members))
    LogIn =>
      Some(UserLogIn(username=self.ui.username, password=self.ui.password))
    SignUp =>
      Some(UserSignUp(username=self.ui.username, password=self.ui.password))
    LogOut => Some(UserLogOut)
    PostBulletin => {
      let text = self.ui.bulletin_draft
      if text == "" {
        None
      } else {
        self.ui = { ..self.ui, bulletin_draft: "" }
        Some(BulletinPost(text=text))
      }
    }
    ReconnectSocket => {
      self.ui = { ..self.ui, connection: Connecting }
      None
    }
    ClearMessage(id) => Some(SessionRemoveMessage(id=id))
    SocketOpened => {
      self.ui = { ..self.ui, connection: Open }
      None
    }
    SocketClosed => {
      self.ui = { ..self.ui, connection: Closed }
      None
    }
    ReceiveSnapshot(store) => {
      self.remote = store
      None
    }
    ReceiveDelta(patches) => {
      let next_remote : @shared.ClientView = @recollect.apply_to_value(
        self.remote,
        patches,
      ) catch {
        _ => self.remote
      }
      self.remote = next_remote
      None
    }
  }
}