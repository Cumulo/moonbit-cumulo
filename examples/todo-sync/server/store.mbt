///|
pub(all) struct ServerStore {
  mut seq : Int
  mut state : @shared.AppState
} derive(Debug)

///|
pub fn ServerStore::new(initial_state : @shared.AppState) -> ServerStore {
  { seq: 0, state: initial_state }
}

///|
pub fn ServerStore::state(self : ServerStore) -> @shared.AppState {
  self.state
}

///|
pub fn ServerStore::snapshot(self : ServerStore) -> @shared.SyncMessage {
  Snapshot(seq=self.seq, state=self.state)
}

///|
pub fn ServerStore::dispatch(
  self : ServerStore,
  action : @shared.ClientAction,
) -> @shared.SyncMessage {
  let old_state = self.state
  let next_state = @shared.reduce_state(old_state, action)
  let patches = @recollect.diff_value(old_state, next_state)
  self.seq = self.seq + 1
  self.state = next_state
  Delta(seq=self.seq, patches~)
}
