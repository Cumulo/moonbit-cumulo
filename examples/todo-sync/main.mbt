///|
fn main {
  let server = @server.ServerStore::new(@shared.sample_old_state())
  let client = @client.ClientStore::new(@shared.sample_old_state())
  let actions : Array[@shared.ClientAction] = [
    ChangePage(page=Detail(id="t-2")),
    UpdateDraft(text=Some("Patch moved through SyncMessage JSON")),
    ToggleTodo(id="t-1"),
    AddTodo(title="Ship client/server application example"),
    MoveTodoToFront(id="t-3"),
    RemoveTodo(id="t-2"),
  ]

  println("Initial snapshot:")
  let snapshot = server.snapshot()
  println(snapshot.to_json().stringify(indent=2))
  client.apply(snapshot) catch {
    _ => panic()
  }

  for action in actions {
    println("Action:")
    println(action.to_json().stringify(indent=2))
    let message = server.dispatch(action)
    println("Delta:")
    println(message.to_json().stringify(indent=2))
    client.apply(message) catch {
      _ => panic()
    }
  }

  println("Final states match:")
  println((client.state() == server.state()).to_string())
  println("Final client state:")
  println(client.state().to_json().stringify(indent=2))
  println("Patch debug view:")
  println(@debug.to_string(server.snapshot()))
}
