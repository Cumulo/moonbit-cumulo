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
pub(all) enum ClientAction {
  ChangePage(page~ : Page)
  UpdateDraft(text~ : String?)
  AddTodo(title~ : String)
  ToggleTodo(id~ : String)
  RemoveTodo(id~ : String)
  MoveTodoToFront(id~ : String)
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) enum SyncMessage {
  Snapshot(seq~ : Int, state~ : AppState)
  Delta(seq~ : Int, patches~ : Array[@recollect.PatchOp])
} derive(Eq, Debug, FromJson, ToJson)

///|
pub fn reduce_state(state : AppState, action : ClientAction) -> AppState {
  match action {
    ChangePage(page~) => { ..state, page, }
    UpdateDraft(text~) => { ..state, draft: text }
    AddTodo(title~) => {
      let next_id = "t-\{state.todos.length() + 1}"
      let todo : Todo = { id: next_id, title, done: false }
      { ..state, todos: state.todos + [todo] }
    }
    ToggleTodo(id~) => {
      let todos = state.todos.map(todo => {
        if todo.id == id {
          { ..todo, done: !todo.done }
        } else {
          todo
        }
      })
      { ..state, todos, }
    }
    RemoveTodo(id~) => {
      let todos = state.todos.filter(todo => todo.id != id)
      { ..state, todos, }
    }
    MoveTodoToFront(id~) => {
      let found = state.todos.search_by(todo => todo.id == id)
      match found {
        Some(index) => {
          let todo = state.todos[index]
          let todos = state.todos.copy()
          ignore(todos.remove(index))
          todos.insert(0, todo)
          { ..state, todos, }
        }
        None => state
      }
    }
  }
}
