///|
pub(all) enum Page {
  Home
  Detail(id~ : String)
} derive(Eq, Debug, FromJson(style="legacy"), ToJson(style="legacy"))

///|
pub(all) struct Todo {
  id : String
  title : String
  done : Bool
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) struct AppState {
  page : Page
  draft : String?
  todos : Array[Todo]
} derive(Eq, Debug, FromJson, ToJson)

///|
pub fn sample_old_state() -> AppState {
  {
    page: Home,
    draft: None,
    todos: [
      { id: "t-1", title: "Design transport tree", done: false },
      { id: "t-2", title: "Ship basic patch ops", done: false },
    ],
  }
}

///|
pub fn sample_new_state() -> AppState {
  {
    page: Detail(id="t-2"),
    draft: Some("Patch is computed on Json"),
    todos: [
      { id: "t-1", title: "Design transport tree", done: true },
      { id: "t-2", title: "Ship basic patch ops", done: false },
      { id: "t-3", title: "Verify round-trip decode", done: false },
    ],
  }
}

///|
pub fn diff_json(old_json : Json, new_json : Json) -> Array[@recollect.PatchOp] {
  @recollect.diff_json(old_json, new_json)
}

///|
pub fn[T : ToJson] diff_value(
  old_value : T,
  new_value : T,
) -> Array[@recollect.PatchOp] {
  @recollect.diff_value(old_value, new_value)
}

///|
pub fn apply_patch(root : Json, patch : @recollect.PatchOp) -> Json {
  @recollect.apply_patch(root, patch)
}

///|
pub fn apply_patches(root : Json, patches : Array[@recollect.PatchOp]) -> Json {
  @recollect.apply_patches(root, patches)
}

///|
pub fn[T : ToJson + FromJson] apply_to_value(
  value : T,
  patches : Array[@recollect.PatchOp],
) -> T raise @json.JsonDecodeError {
  @recollect.apply_to_value(value, patches)
}
