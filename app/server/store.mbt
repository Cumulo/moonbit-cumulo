///|
pub(all) struct SessionEvent {
  sid : String
  payload : @shared.ServerEvent
} derive(Eq, Debug)

///|
pub(all) struct FullstackServer {
  mut seq : Int
  mut db : @shared.AppDb
  mut caches : Map[String, @shared.ClientView]
} derive(Debug)

///|
pub fn FullstackServer::new(initial_db : @shared.AppDb) -> FullstackServer {
  { seq: 0, db: initial_db, caches: {} }
}

///|
pub fn FullstackServer::db(self : FullstackServer) -> @shared.AppDb {
  self.db
}

///|
fn FullstackServer::sync_all(self : FullstackServer) -> Array[SessionEvent] {
  let outbound = Array::new()
  let next_caches = self.caches.copy()
  let mut did_bump = false

  for sid, session in self.db.sessions {
    let next_view = @shared.twig_container(self.db, session)
    match self.caches.get(sid) {
      Some(previous) =>
        if previous != next_view {
          if !did_bump {
            self.seq = self.seq + 1
            did_bump = true
          }
          let patches = @recollect.diff_value(previous, next_view)
          if patches.length() > 0 {
            outbound.push({ sid, payload: Delta(seq=self.seq, patches~) })
          }
        }
      None => {
        if !did_bump {
          self.seq = self.seq + 1
          did_bump = true
        }
        outbound.push({ sid, payload: Snapshot(seq=self.seq, store=next_view) })
      }
    }
    next_caches.set(sid, next_view)
  }

  for sid, _ in self.caches {
    if !self.db.sessions.contains(sid) {
      next_caches.remove(sid) |> ignore
    }
  }

  self.caches = next_caches
  outbound
}

///|
pub fn FullstackServer::connect(
  self : FullstackServer,
  sid : String,
) -> Array[SessionEvent] {
  self.db = @shared.connect_session(self.db, sid)
  self.sync_all()
}

///|
pub fn FullstackServer::disconnect(
  self : FullstackServer,
  sid : String,
) -> Array[SessionEvent] {
  self.db = @shared.disconnect_session(self.db, sid)
  let next_caches = self.caches.copy()
  next_caches.remove(sid) |> ignore
  self.caches = next_caches
  self.sync_all()
}

///|
pub fn FullstackServer::dispatch(
  self : FullstackServer,
  sid : String,
  op : @shared.ClientOp,
  op_id : String,
) -> Array[SessionEvent] {
  self.db = @shared.updater(self.db, sid, op, op_id)
  self.sync_all()
}

///|
fn find_session_event(
  events : Array[SessionEvent],
  sid : String,
) -> SessionEvent? {
  for event in events {
    if event.sid == sid {
      return Some(event)
    }
  }
  None
}

///|
test "connect emits a snapshot" {
  let server = FullstackServer::new(@shared.initial_db())
  let events = server.connect("sid-1")
  assert_eq(events.length(), 1)
  match events[0].payload {
    Snapshot(seq~, store~) => {
      assert_eq(seq, 1)
      assert_eq(store.session_id, "sid-1")
      assert_true(!store.logged_in)
    }
    Delta(..) => panic()
  }
}

///|
test "login emits a delta for the active client" {
  let server = FullstackServer::new(@shared.initial_db())
  ignore(server.connect("sid-2"))
  let events = server.dispatch(
    "sid-2",
    UserLogIn(username="demo", password="demo"),
    "op-login",
  )
  match find_session_event(events, "sid-2") {
    Some(event) =>
      match event.payload {
        Snapshot(..) => panic()
        Delta(seq~, patches~) => {
          assert_eq(seq, 2)
          assert_true(patches.length() > 0)
        }
      }
    None => panic()
  }
}

///|
test "bulletin post emits deltas to other sessions" {
  let server = FullstackServer::new(@shared.initial_db())
  ignore(server.connect("sid-a"))
  ignore(server.connect("sid-b"))
  ignore(
    server.dispatch(
      "sid-a",
      UserLogIn(username="demo", password="demo"),
      "op-login",
    ),
  )
  let events = server.dispatch(
    "sid-a",
    BulletinPost(text="Shared update"),
    "op-bulletin",
  )
  let first = find_session_event(events, "sid-a").unwrap()
  let second = find_session_event(events, "sid-b").unwrap()
  match first.payload {
    Snapshot(..) => panic()
    Delta(seq~, patches~) => {
      assert_eq(seq, 4)
      assert_true(patches.length() > 0)
    }
  }
  match second.payload {
    Snapshot(..) => panic()
    Delta(seq~, patches~) => {
      assert_eq(seq, 4)
      assert_true(patches.length() > 0)
    }
  }
}
