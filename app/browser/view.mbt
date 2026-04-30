///|
using @respo_node {
  div,
  span,
  button,
  input,
  p,
  h1,
  h2,
  h3,
  text_node,
  type RespoEvent,
  type RespoNode,
  type DispatchFn,
  type RespoCommonError,
}

///|
using @css {respo_style}

///|
fn on_click_action(
  action : ActionOp,
) -> (RespoEvent, DispatchFn[ActionOp]) -> Unit raise RespoCommonError {
  (e, dispatch) => {
    if e is Click(original_event~, ..) {
      original_event.prevent_default()
    }
    dispatch.run(action)
  }
}

///|
fn on_input_action(
  build : (String) -> ActionOp,
) -> (RespoEvent, DispatchFn[ActionOp]) -> Unit raise RespoCommonError {
  (e, dispatch) => {
    match e {
      Input(value~, ..) => dispatch.run(build(value))
      _ => ()
    }
  }
}

///|
fn connection_label(state : ConnectionState) -> String {
  match state {
    Connecting => "Connecting"
    Open => "Live"
    Closed => "Closed"
  }
}

///|
fn connection_class(state : ConnectionState) -> String {
  match state {
    Open => "status-badge is-live"
    Connecting => "status-badge is-connecting"
    Closed => "status-badge is-closed"
  }
}

///|
fn render_messages(messages : Array[@shared.FlashMessage]) -> Array[RespoNode[ActionOp]] {
  let items = Array::new(capacity=messages.length())
  for message in messages {
    let kind = match message.kind {
      Info => "toast is-info"
      Error => "toast is-error"
    }
    let title = match message.kind {
      Info => "Info"
      Error => "Error"
    }
    items.push(
      div(class_name=kind, [
        div([
          span(class_name="toast-title", inner_text=title, []),
          p(inner_text=message.text, []),
        ]),
        button(
          class_name="ghost",
          inner_text="Dismiss",
          on_click=on_click_action(ClearMessage(message.id)),
        ),
      ]),
    )
  }
  items
}

///|
fn render_members(members : Array[@shared.MemberView]) -> Array[RespoNode[ActionOp]] {
  let items = Array::new(capacity=members.length())
  for person in members {
    items.push(
      div(class_name="member-card", [
        h3(inner_text=person.name, []),
        p(inner_text="id: \{person.id}", []),
      ]),
    )
  }
  items
}

///|
fn render_bulletins(
  bulletins : Array[@shared.BulletinEntry],
) -> Array[RespoNode[ActionOp]] {
  if bulletins.length() == 0 {
    return [
      div(class_name="bulletin-card is-empty", [
        p(inner_text="No bulletins yet.", []),
      ]),
    ]
  }
  let items = Array::new(capacity=bulletins.length())
  for bulletin in bulletins {
    items.push(
      div(class_name="bulletin-card", [
        p(class_name="bulletin-meta", inner_text=bulletin.author, []),
        p(class_name="bulletin-text", inner_text=bulletin.text, []),
      ]),
    )
  }
  items
}

///|
fn render_auth_panel(store : Store) -> RespoNode[ActionOp] {
  match store.remote.current_user {
    Some(user) =>
      div(class_list=["panel", "auth-panel"], [
        p(class_name="eyebrow", inner_text="Current session", []),
        h2(inner_text=user.name, []),
        p(inner_text="session: \{store.remote.session_id}", []),
        p(
          inner_text="connection: \{connection_label(store.ui.connection)}",
          [],
        ),
        div(class_name="auth-actions", [
          button(
            class_name="solid",
            inner_text="Browse members",
            on_click=on_click_action(RouteMembers),
          ),
          button(
            class_name="ghost",
            inner_text="Log out",
            on_click=on_click_action(LogOut),
          ),
        ]),
      ])
    None => {
      let login_class = if store.ui.auth_mode == Login {
        "tab is-active"
      } else {
        "tab"
      }
      let signup_class = if store.ui.auth_mode == SignUp {
        "tab is-active"
      } else {
        "tab"
      }
      let submit_label = if store.ui.auth_mode == Login {
        "Log in"
      } else {
        "Create account"
      }
      let submit_action = if store.ui.auth_mode == Login {
        LogIn
      } else {
        SignUp
      }
      div(class_list=["panel", "auth-panel"], [
        p(class_name="eyebrow", inner_text="Account", []),
        div(class_name="tabs", [
          button(
            class_name=login_class,
            inner_text="Login",
            on_click=on_click_action(SetAuthMode(Login)),
          ),
          button(
            class_name=signup_class,
            inner_text="Sign up",
            on_click=on_click_action(SetAuthMode(SignUp)),
          ),
        ]),
        div(class_name="field", [
          span(inner_text="Username", []),
          input(
            value=store.ui.username,
            placeholder="demo",
            on_input=on_input_action(fn(value) { UpdateUsername(value) }),
          ),
        ]),
        div(class_name="field", [
          span(inner_text="Password", []),
          input(
            value=store.ui.password,
            placeholder="demo",
            attrs={ "type": "password" },
            on_input=on_input_action(fn(value) { UpdatePassword(value) }),
          ),
        ]),
        div(class_name="auth-actions", [
          button(
            class_name="solid",
            inner_text=submit_label,
            on_click=on_click_action(submit_action),
          ),
          button(
            class_name="ghost",
            inner_text="Use demo/demo",
            on_click=on_click_action(FillDemo),
          ),
        ]),
      ])
    }
  }
}

///|
fn render_home(store : Store) -> RespoNode[ActionOp] {
  let bulletins = render_bulletins(store.remote.bulletins)
  let composer = if store.remote.logged_in {
    [
      div(class_name="bulletin-composer", [
        div(class_name="field", [
          span(inner_text="Post an update for every connected page", []),
          input(
            value=store.ui.bulletin_draft,
            placeholder="Ship note, deployment update, etc.",
            on_input=on_input_action(fn(value) { UpdateBulletinDraft(value) }),
          ),
        ]),
        button(
          class_name="solid",
          inner_text="Post bulletin",
          on_click=on_click_action(PostBulletin),
        ),
      ]),
    ]
  } else {
    [
      p(
        class_name="board-note",
        inner_text="Log in to post on the shared bulletin board. Other tabs will receive the update as a delta.",
        [],
      ),
    ]
  }
  div([
    div(class_list=["panel", "content-panel"], [
      p(class_name="eyebrow", inner_text="Home", []),
      h2(inner_text="How this mirrors Cumulo", []),
      div(class_name="feature-grid", [
        div(class_name="feature-card", [
          h3(inner_text="Authoritative server", []),
          p(
            inner_text="The server keeps the full AppDb and applies a pure updater for every client operation.",
            [],
          ),
        ]),
        div(class_name="feature-card", [
          h3(inner_text="Session twig", []),
          p(
            inner_text="Each WebSocket client receives a filtered ClientView, not the raw database.",
            [],
          ),
        ]),
        div(class_name="feature-card", [
          h3(inner_text="Diff over WebSocket", []),
          p(
            inner_text="After the first snapshot, later changes go out as structural patches built by diff_value.",
            [],
          ),
        ]),
      ]),
    ]),
    div(class_list=["panel", "content-panel"], [
      div(class_name="board-header", [
        div([
          p(class_name="eyebrow", inner_text="Bulletin board", []),
          h2(inner_text="Shared demo state", []),
        ]),
        span(
          class_name="board-count",
          inner_text="\{store.remote.bulletins.length()} posts",
          [],
        ),
      ]),
      p(
        class_name="board-note",
        inner_text="Use this to verify that one page can mutate shared state and every other page patches into the new projection.",
        [],
      ),
      div(composer + [div(class_name="bulletin-list", bulletins)]),
    ]),
  ])
}

///|
fn render_members_route(store : Store) -> RespoNode[ActionOp] {
  div(class_list=["panel", "content-panel"], [
    p(class_name="eyebrow", inner_text="Members", []),
    h2(inner_text="Known users", []),
    div(class_name="member-grid", render_members(store.remote.members)),
  ])
}

///|
fn view(store : Store) -> RespoNode[ActionOp] {
  let viewer = match store.remote.current_user {
    Some(user) => user.name
    None => "guest"
  }
  let reconnect_nodes = if store.ui.connection == Closed {
    [
      button(
        class_name="ghost",
        inner_text="Reconnect",
        on_click=on_click_action(ReconnectSocket),
      ),
    ]
  } else {
    []
  }
  let route_node = match store.remote.route {
    Home => render_home(store)
    Members => render_members_route(store)
  }
  div(
    class_name="shell",
    class_list=[@respo.ui_global],
    style=respo_style().add("--accent", store.remote.accent),
    [
      div(class_name="hero", [
        div([
          p(class_name="eyebrow", inner_text="MoonBit + Cumulo", []),
          h1(inner_text="Realtime fullstack patch sync", []),
          p(class_name="lead", inner_text=store.remote.welcome, []),
        ]),
        div(class_name="hero-meta", [
          span(
            class_name=connection_class(store.ui.connection),
            inner_text=connection_label(store.ui.connection),
            [],
          ),
          div(class_name="hero-stats", [
            text_node(store.remote.viewer_count.to_string()),
            span(inner_text="viewers", []),
          ]),
          div(class_name="hero-stats", [
            text_node(store.remote.member_count.to_string()),
            span(inner_text="users", []),
          ]),
        ] + reconnect_nodes),
      ]),
      div(class_name="nav", [
        button(
          class_name=if store.remote.route == Home {
            "nav-link is-active"
          } else {
            "nav-link"
          },
          inner_text="Home",
          on_click=on_click_action(RouteHome),
        ),
        button(
          class_name=if store.remote.route == Members {
            "nav-link is-active"
          } else {
            "nav-link"
          },
          inner_text="Members",
          on_click=on_click_action(RouteMembers),
        ),
        span(class_name="nav-user", inner_text="viewer: \{viewer}", []),
      ]),
      div(class_name="layout", [
        div(class_name="sidebar", [
          render_auth_panel(store),
          div(class_list=["panel", "tips"], [
            p(class_name="eyebrow", inner_text="Transport", []),
            p(
              inner_text="Snapshot on connect. Delta patches afterwards. The browser applies patches to a typed ClientView.",
              [],
            ),
          ]),
        ]),
        div(class_name="main", [
          div(render_messages(store.remote.messages)),
          route_node,
        ]),
      ]),
    ],
  )
}