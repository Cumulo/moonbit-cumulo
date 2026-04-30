///|
pub(all) enum ClientAction {
  ChangePage(page~ : @cumulo.Page)
  UpdateDraft(text~ : String?)
  AddTodo(title~ : String)
  ToggleTodo(id~ : String)
  RemoveTodo(id~ : String)
  MoveTodoToFront(id~ : String)
} derive(Eq, Debug, FromJson, ToJson)

///|
pub(all) enum SyncMessage {
  Snapshot(seq~ : Int, state~ : @cumulo.AppState)
  Delta(seq~ : Int, patches~ : Array[@recollect.PatchOp])
} derive(Eq, Debug, FromJson, ToJson)

///|
pub fn reduce_state(
  state : @cumulo.AppState,
  action : ClientAction,
) -> @cumulo.AppState {
  match action {
    ChangePage(page~) => { ..state, page, }
    UpdateDraft(text~) => { ..state, draft: text }
    AddTodo(title~) => {
      let next_id = "t-\{state.todos.length() + 1}"
      let todo : @cumulo.Todo = { id: next_id, title, done: false }
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
