///|
test "sample state round-trip through json" {
  let state = sample_new_state()
  let json = state.to_json()
  let decoded : AppState = @json.from_json(json)
  assert_true(decoded == state)
}

///|
test "diff patches rebuild next state" {
  let old_state = sample_old_state()
  let new_state = sample_new_state()
  let patches = @recollect.diff_value(old_state, new_state)
  assert_true(patches.length() > 0)
  let rebuilt : AppState = @recollect.apply_to_value(old_state, patches)
  assert_true(rebuilt == new_state)
}
