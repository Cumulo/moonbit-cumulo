///|
pub(all) enum Route {
  Home
  Members
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) enum MessageKind {
  Info
  Error
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) struct FlashMessage {
  id : String
  text : String
  kind : MessageKind
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) struct UserRecord {
  id : String
  name : String
  password : String
} derive(Eq, Debug)

///|
pub(all) struct BulletinEntry {
  id : String
  author : String
  text : String
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) struct SessionRecord {
  id : String
  user_id : String?
  router : Route
  messages : Array[FlashMessage]
} derive(Eq, Debug)

///|
pub(all) struct AppDb {
  users : Map[String, UserRecord]
  bulletins : Array[BulletinEntry]
  sessions : Map[String, SessionRecord]
} derive(Eq, Debug)

///|
pub(all) struct MemberView {
  id : String
  name : String
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) struct ClientView {
  session_id : String
  route : Route
  logged_in : Bool
  accent : String
  welcome : String
  current_user : MemberView?
  bulletins : Array[BulletinEntry]
  members : Array[MemberView]
  member_count : Int
  viewer_count : Int
  messages : Array[FlashMessage]
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) enum ClientOp {
  UserLogIn(username~ : String, password~ : String)
  UserSignUp(username~ : String, password~ : String)
  UserLogOut
  BulletinPost(text~ : String)
  RouteChange(route~ : Route)
  SessionRemoveMessage(id~ : String)
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) enum ServerEvent {
  Snapshot(seq~ : Int, store~ : ClientView)
  Delta(seq~ : Int, patches~ : Array[@recollect.PatchOp])
} derive(Eq, Debug, FromJson, ToJson)

///|
fn demo_users() -> Map[String, UserRecord] {
  let users = {}
  let demo : UserRecord = { id: "u-demo", name: "demo", password: "demo" }
  let alice : UserRecord = { id: "u-alice", name: "alice", password: "moon" }
  users.set(demo.id, demo)
  users.set(alice.id, alice)
  users
}

///|
fn demo_bulletins() -> Array[BulletinEntry] {
  [
    {
      id: "b-demo-2",
      author: "alice",
      text: "Switch routes in one tab and post updates from another to watch deltas land live.",
    },
    {
      id: "b-demo-1",
      author: "demo",
      text: "This shared bulletin board lives in AppDb and syncs to every connected page.",
    },
  ]
}

///|
pub fn initial_db() -> AppDb {
  { users: demo_users(), bulletins: demo_bulletins(), sessions: {} }
}

///|
fn session_message(
  text : String,
  kind : MessageKind,
  id : String,
) -> FlashMessage {
  { id, text, kind }
}

///|
fn put_session(db : AppDb, session : SessionRecord) -> AppDb {
  let sessions = db.sessions.copy()
  sessions.set(session.id, session)
  { ..db, sessions, }
}

///|
fn put_user(db : AppDb, user : UserRecord) -> AppDb {
  let users = db.users.copy()
  users.set(user.id, user)
  { ..db, users, }
}

///|
fn push_bulletin(db : AppDb, bulletin : BulletinEntry) -> AppDb {
  let bulletins = db.bulletins.copy()
  bulletins.insert(0, bulletin)
  { ..db, bulletins, }
}

///|
fn remove_session(db : AppDb, sid : String) -> AppDb {
  let sessions = db.sessions.copy()
  sessions.remove(sid) |> ignore
  { ..db, sessions, }
}

///|
fn add_message(
  session : SessionRecord,
  message : FlashMessage,
) -> SessionRecord {
  let messages = session.messages.copy()
  messages.insert(0, message)
  { ..session, messages, }
}

///|
fn clear_messages(session : SessionRecord) -> SessionRecord {
  { ..session, messages: [] }
}

///|
fn current_user(db : AppDb, session : SessionRecord) -> UserRecord? {
  match session.user_id {
    Some(user_id) => db.users.get(user_id)
    None => None
  }
}

///|
fn member_view(user : UserRecord) -> MemberView {
  { id: user.id, name: user.name }
}

///|
fn find_user_by_name(db : AppDb, username : String) -> UserRecord? {
  for _, user in db.users {
    if user.name == username {
      return Some(user)
    }
  }
  None
}

///|
fn accent_for(_sid : String) -> String {
  "#0f766e"
}

///|
fn welcome_for(_session : SessionRecord, user : UserRecord?) -> String {
  match user {
    Some(found) =>
      "Hello, \{found.name}. Your client store is patched over WebSocket."
    None =>
      "MoonBit Cumulo demo: sign in with demo/demo or create a new account."
  }
}

///|
pub fn connect_session(db : AppDb, sid : String) -> AppDb {
  if db.sessions.contains(sid) {
    return db
  }
  let session : SessionRecord = {
    id: sid,
    user_id: None,
    router: Home,
    messages: [
      session_message(
        "Connected. Use demo/demo for a quick smoke test.",
        Info,
        "\{sid}-welcome",
      ),
    ],
  }
  put_session(db, session)
}

///|
pub fn disconnect_session(db : AppDb, sid : String) -> AppDb {
  if !db.sessions.contains(sid) {
    return db
  }
  remove_session(db, sid)
}

///|
fn update_session(
  db : AppDb,
  sid : String,
  f : (SessionRecord) -> SessionRecord,
) -> AppDb {
  match db.sessions.get(sid) {
    Some(session) => put_session(db, f(session))
    None => db
  }
}

///|
fn invalid_message(
  db : AppDb,
  sid : String,
  message : String,
  op_id : String,
) -> AppDb {
  update_session(db, sid, session => {
    add_message(session, session_message(message, Error, "\{op_id}-error"))
  })
}

///|
fn session_user(session : SessionRecord, user : UserRecord) -> SessionRecord {
  add_message(
    clear_messages({ ..session, user_id: Some(user.id) }),
    session_message("Logged in as \{user.name}.", Info, "login-ok"),
  )
}

///|
fn post_bulletin(
  db : AppDb,
  sid : String,
  text : String,
  op_id : String,
) -> AppDb {
  if text == "" {
    return invalid_message(db, sid, "Bulletin text is required.", op_id)
  }
  match db.sessions.get(sid) {
    Some(session) =>
      match current_user(db, session) {
        Some(user) => push_bulletin(db, { id: op_id, author: user.name, text })
        None =>
          invalid_message(
            db, sid, "Log in before posting to the bulletin board.", op_id,
          )
      }
    None => db
  }
}

///|
pub fn updater(
  db : AppDb,
  sid : String,
  op : ClientOp,
  op_id : String,
) -> AppDb {
  match op {
    UserLogIn(username~, password~) => {
      if username == "" || password == "" {
        return invalid_message(
          db, sid, "Username and password are required.", op_id,
        )
      }
      match find_user_by_name(db, username) {
        Some(user) =>
          if user.password == password {
            update_session(db, sid, session => session_user(session, user))
          } else {
            invalid_message(db, sid, "Password mismatch.", op_id)
          }
        None =>
          invalid_message(db, sid, "Unknown user. Create one first.", op_id)
      }
    }
    UserSignUp(username~, password~) => {
      if username.length() < 3 {
        return invalid_message(
          db, sid, "Choose a username with at least 3 characters.", op_id,
        )
      }
      if password.length() < 3 {
        return invalid_message(
          db, sid, "Choose a password with at least 3 characters.", op_id,
        )
      }
      if find_user_by_name(db, username) is Some(_) {
        return invalid_message(db, sid, "That username already exists.", op_id)
      }
      let user : UserRecord = { id: op_id, name: username, password }
      let with_user = put_user(db, user)
      update_session(with_user, sid, session => session_user(session, user))
    }
    UserLogOut =>
      update_session(db, sid, session => {
        add_message(
          clear_messages({ ..session, user_id: None, router: Home }),
          session_message("Logged out.", Info, "logout-ok"),
        )
      })
    BulletinPost(text~) => post_bulletin(db, sid, text, op_id)
    RouteChange(route~) =>
      update_session(db, sid, session => { ..session, router: route })
    SessionRemoveMessage(id~) =>
      update_session(db, sid, session => {
        let messages = session.messages.filter(message => message.id != id)
        { ..session, messages, }
      })
  }
}

///|
pub fn twig_container(db : AppDb, session : SessionRecord) -> ClientView {
  let members = Array::new(capacity=db.users.length())
  for _, user in db.users {
    members.push(member_view(user))
  }
  let maybe_user = current_user(db, session)
  let user_view = match maybe_user {
    Some(user) => Some(member_view(user))
    None => None
  }
  {
    session_id: session.id,
    route: session.router,
    logged_in: maybe_user is Some(_),
    accent: accent_for(session.id),
    welcome: welcome_for(session, maybe_user),
    current_user: user_view,
    bulletins: db.bulletins,
    members,
    member_count: db.users.length(),
    viewer_count: db.sessions.length(),
    messages: session.messages,
  }
}

///|
pub fn empty_view(sid : String) -> ClientView {
  {
    session_id: sid,
    route: Home,
    logged_in: false,
    accent: accent_for(sid),
    welcome: "Connecting to MoonBit Cumulo demo...",
    current_user: None,
    bulletins: [],
    members: [],
    member_count: 0,
    viewer_count: 0,
    messages: [],
  }
}

///|
test "login updates projected store with diff patches" {
  let before = connect_session(initial_db(), "sid-a")
  let after = updater(
    before,
    "sid-a",
    UserLogIn(username="demo", password="demo"),
    "op-1",
  )
  let old_view = twig_container(before, before.sessions.get("sid-a").unwrap())
  let new_view = twig_container(after, after.sessions.get("sid-a").unwrap())
  let patches = @recollect.diff_value(old_view, new_view)
  let rebuilt = @recollect.apply_to_value(old_view, patches)
  assert_true(rebuilt == new_view)
}

///|
test "sign up creates a new logged in user" {
  let db = connect_session(initial_db(), "sid-b")
  let next = updater(
    db,
    "sid-b",
    UserSignUp(username="mika", password="mika-1"),
    "u-mika",
  )
  let session = next.sessions.get("sid-b").unwrap()
  assert_true(session.user_id == Some("u-mika"))
  assert_true(find_user_by_name(next, "mika") is Some(_))
}

///|
test "bulletin posts are shared through projected state" {
  let db0 = connect_session(connect_session(initial_db(), "sid-a"), "sid-b")
  let db1 = updater(
    db0,
    "sid-a",
    UserLogIn(username="demo", password="demo"),
    "op-login",
  )
  let db2 = updater(
    db1,
    "sid-a",
    BulletinPost(text="Ship the sync demo."),
    "op-bulletin",
  )
  let before = twig_container(db1, db1.sessions.get("sid-b").unwrap())
  let after = twig_container(db2, db2.sessions.get("sid-b").unwrap())
  let patches = @recollect.diff_value(before, after)
  let rebuilt = @recollect.apply_to_value(before, patches)
  assert_eq(after.bulletins[0].text, "Ship the sync demo.")
  assert_eq(after.bulletins[0].author, "demo")
  assert_true(rebuilt == after)
}
