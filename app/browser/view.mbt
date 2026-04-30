///|
using @respo_node {
  div,
  div_listed,
  span,
  button,
  input,
  p,
  type RespoEvent,
  type RespoNode,
  type RespoIndexKey,
  type DispatchFn,
  type RespoCommonError,
  static_style,
}

///|
using @css {respo_style}

// ---- Static styles ----

///|
let s_layout : String = static_style([
  (
    "&",
    respo_style(
      display=Grid,
      gap=Px(10),
      grid_template_columns=Sizes([Px(260), Fr(1)]),
    ),
  ),
])

///|
let s_col : String = static_style([
  ("&", respo_style(display=Grid, gap=Px(10)).add("align-content", "start")),
])

///|
let s_row : String = static_style([
  ("&", respo_style(display=Flex, gap=Px(8)).add("flex-wrap", "wrap")),
])

///|
let s_field : String = static_style([
  ("&", respo_style(display=Grid, gap=Px(4), margin_bottom=Px(8))),
  ("& input", respo_style(width=Percent(100))),
])

///|
let s_label : String = static_style([
  ("&", respo_style(font_size=12, color=Var("--muted"))),
])

///|
let s_section_head : String = static_style([
  (
    "&",
    respo_style(
      display=Flex,
      justify_content=SpaceBetween,
      align_items=Center,
      margin_bottom=Px(8),
    ),
  ),
])

///|
let s_bulletin_item : String = static_style([
  (
    "&",
    respo_style(
      border_bottom=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.08),
      ),
      padding_top=Px(6),
      padding_bottom=Px(6),
    ),
  ),
])

///|
let s_meta : String = static_style([
  ("&", respo_style(font_size=11, color=Var("--muted"), margin_bottom=Px(2))),
])

///|
let s_muted : String = static_style([
  ("&", respo_style(color=Var("--muted"), font_size=12)),
])

///|
let s_member_item : String = static_style([
  (
    "&",
    respo_style(
      padding_top=Px(4),
      padding_bottom=Px(4),
      border_bottom=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.08),
      ),
    ),
  ),
])

// ---- Helpers ----

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
    Open => "badge-live"
    Connecting => "badge-connecting"
    Closed => "badge-closed"
  }
}

// ---- Sub-panels ----

///|
fn render_messages(
  messages : Array[@shared.FlashMessage],
) -> Array[RespoNode[ActionOp, Unit]] {
  messages.map(fn(m) {
    let cls = match m.kind {
      Info => "toast-info"
      Error => "toast-error"
    }
    div(class_name=cls, [
      p(inner_text=m.text, []),
      button(
        class_name="ghost",
        inner_text="×",
        on_click=on_click_action(ClearMessage(m.id)),
      ),
    ])
  })
}

///|
fn render_auth_panel(store : Store) -> RespoNode[ActionOp, Unit] {
  match store.remote.current_user {
    Some(user) =>
      div(class_name="panel", [
        div(class_name=s_section_head, [
          span(inner_text="Session", class_name=s_label, []),
          button(
            class_name="ghost",
            inner_text="Log out",
            on_click=on_click_action(LogOut),
          ),
        ]),
        p(inner_text="👤 \{user.name}", []),
        p(class_name=s_muted, inner_text="sid: \{store.remote.session_id}", []),
      ])
    None => {
      let submit_label = if store.ui.auth_mode == Login {
        "Log in"
      } else {
        "Sign up"
      }
      let submit_action = if store.ui.auth_mode == Login {
        LogIn
      } else {
        SignUp
      }
      div(class_name="panel", [
        div(class_name=s_row, [
          button(
            class_name=if store.ui.auth_mode == Login {
              "tab is-active"
            } else {
              "tab"
            },
            inner_text="Login",
            on_click=on_click_action(SetAuthMode(Login)),
          ),
          button(
            class_name=if store.ui.auth_mode == SignUp {
              "tab is-active"
            } else {
              "tab"
            },
            inner_text="Sign up",
            on_click=on_click_action(SetAuthMode(SignUp)),
          ),
        ]),
        div(class_name=s_field, [
          span(class_name=s_label, inner_text="Username", []),
          input(
            value=store.ui.username,
            placeholder="demo",
            on_input=on_input_action(fn(v) { UpdateUsername(v) }),
          ),
        ]),
        div(class_name=s_field, [
          span(class_name=s_label, inner_text="Password", []),
          input(
            value=store.ui.password,
            placeholder="demo",
            attrs={ "type": "password" },
            on_input=on_input_action(fn(v) { UpdatePassword(v) }),
          ),
        ]),
        div(class_name=s_row, [
          button(
            class_name="solid",
            inner_text=submit_label,
            on_click=on_click_action(submit_action),
          ),
          button(
            class_name="ghost",
            inner_text="demo/demo",
            on_click=on_click_action(FillDemo),
          ),
        ]),
      ])
    }
  }
}

///|
fn render_home(store : Store) -> RespoNode[ActionOp, Unit] {
  let composer = if store.remote.logged_in {
    [
      div(class_name=s_field, [
        span(class_name=s_label, inner_text="New bulletin", []),
        input(
          value=store.ui.bulletin_draft,
          placeholder="Ship note, deployment update…",
          on_input=on_input_action(fn(v) { UpdateBulletinDraft(v) }),
        ),
      ]),
      button(
        class_name="solid",
        inner_text="Post",
        on_click=on_click_action(PostBulletin),
      ),
    ]
  } else {
    [p(class_name=s_muted, inner_text="Log in to post.", [])]
  }
  let bulletin_keyed : Array[(RespoIndexKey, RespoNode[ActionOp, Unit])] = if store.remote.bulletins.length() ==
    0 {
    [
      (
        RespoIndexKey("empty"),
        p(class_name=s_muted, inner_text="No bulletins yet.", []),
      ),
    ]
  } else {
    store.remote.bulletins.map(fn(b) {
      (
        RespoIndexKey(b.id),
        div(class_name=s_bulletin_item, [
          p(class_name=s_meta, inner_text=b.author, []),
          p(inner_text=b.text, []),
        ]),
      )
    })
  }
  div(class_name="panel", [
    div(class_name=s_section_head, [
      span(inner_text="Bulletin Board", class_name=s_label, []),
      span(
        class_name=s_muted,
        inner_text="\{store.remote.bulletins.length()} posts",
        [],
      ),
    ]),
    div(composer),
    div_listed(bulletin_keyed),
  ])
}

///|
fn render_members_route(store : Store) -> RespoNode[ActionOp, Unit] {
  let items = if store.remote.members.length() == 0 {
    [p(class_name=s_muted, inner_text="No members.", [])]
  } else {
    store.remote.members.map(fn(m) {
      div(class_name=s_member_item, [
        span(inner_text="\{m.name} ", []),
        span(class_name=s_muted, inner_text="(\{m.id})", []),
      ])
    })
  }
  div(class_name="panel", [
    span(class_name=s_label, inner_text="Members", []),
    div(items),
  ])
}

// ---- Root view ----

///|
fn view(store : Store) -> RespoNode[ActionOp, Unit] {
  let viewer = match store.remote.current_user {
    Some(user) => user.name
    None => "guest"
  }
  let reconnect = if store.ui.connection == Closed {
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
      div(
        class_name="nav",
        [
          span(
            class_name=connection_class(store.ui.connection),
            inner_text=connection_label(store.ui.connection),
            [],
          ),
          span(
            class_name=s_muted,
            inner_text="\{store.remote.viewer_count}v / \{store.remote.member_count}u",
            [],
          ),
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
          span(class_name=s_muted, inner_text="viewer: \{viewer}", []),
        ] +
        reconnect,
      ),
      div(render_messages(store.remote.messages)),
      div(class_name=s_layout, [
        div(class_name=s_col, [render_auth_panel(store)]),
        div(class_name=s_col, [route_node]),
      ]),
    ],
  )
}
