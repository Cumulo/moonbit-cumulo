///|
pub(all) struct ClientStore {
  mut seq : Int
  mut state : @shared.AppState
} derive(Debug)

///|
pub fn ClientStore::new(initial_state : @shared.AppState) -> ClientStore {
  { seq: 0, state: initial_state }
}

///|
pub fn ClientStore::state(self : ClientStore) -> @shared.AppState {
  self.state
}

///|
pub fn ClientStore::apply(
  self : ClientStore,
  message : @shared.SyncMessage,
) -> Unit raise @json.JsonDecodeError {
  match message {
    Snapshot(seq~, state~) => {
      self.seq = seq
      self.state = state
    }
    Delta(seq~, patches~) => {
      self.seq = seq
      self.state = @recollect.apply_to_value(self.state, patches)
    }
  }
}

///|
fn round_trip_message(
  message : @shared.SyncMessage,
) -> @shared.SyncMessage raise @json.JsonDecodeError {
  @json.from_json(message.to_json())
}

///|
test "client catches up from server deltas over json" {
  let server = @server.ServerStore::new(@shared.sample_old_state())
  let client = ClientStore::new(@shared.sample_old_state())

  let actions : Array[@shared.ClientAction] = [
    ChangePage(page=Detail(id="t-2")),
    UpdateDraft(text=Some("Client received a serialized delta")),
    ToggleTodo(id="t-1"),
    AddTodo(title="Run end-to-end sync test"),
    MoveTodoToFront(id="t-3"),
    RemoveTodo(id="t-2"),
  ]

  for action in actions {
    let outbound = server.dispatch(action)
    let inbound = round_trip_message(outbound)
    client.apply(inbound)
  }

  assert_true(client.state() == server.state())
}

///|
test "snapshot rehydrates client over json" {
  let server = @server.ServerStore::new(@shared.sample_new_state())
  let client = ClientStore::new(@shared.sample_old_state())
  let inbound = round_trip_message(server.snapshot())
  client.apply(inbound)
  assert_true(client.state() == server.state())
}
