///|
test "sample state round-trip through json" {
  let state = @cumulo.sample_new_state()
  let json = state.to_json()
  let decoded : @cumulo.AppState = @json.from_json(json)
  assert_true(decoded == state)
}

///|
test "diff patches rebuild next state" {
  let old_state = @cumulo.sample_old_state()
  let new_state = @cumulo.sample_new_state()
  let patches = @recollect.diff_value(old_state, new_state)
  assert_true(patches.length() > 0)
  let rebuilt : @cumulo.AppState = @recollect.apply_to_value(old_state, patches)
  assert_true(rebuilt == new_state)
}
