///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let old_state = @lib.sample_old_state()
  let new_state = @lib.sample_new_state()
  let patches = @recollect.diff_value(old_state, new_state)
  let rebuilt : @lib.AppState = @recollect.apply_to_value(old_state, patches) catch {
    _ => panic()
  }

  println("Old JSON:")
  println(old_state.to_json().stringify(indent=2))
  println("New JSON:")
  println(new_state.to_json().stringify(indent=2))
  println("Patch ops:")
  println(@debug.to_string(patches))
  println("Patched equals new:")
  println((rebuilt == new_state).to_string())
}
