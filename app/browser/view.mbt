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
  static_style,
  contained_static_style,
}

///|
using @css {respo_style}

// ---- Static style constants ----

///|
let s_layout : String = contained_static_style([
  (
    None,
    "&",
    respo_style(
      display=Grid,
      gap=Px(18),
      grid_template_columns=Sizes([Px(340), Fr(1)]),
    ),
  ),
  (
    Some("@media (max-width: 920px)"),
    "&",
    respo_style(display=Grid, grid_template_columns=Sizes([Fr(1)])),
  ),
])

///|
let s_column_gap : String = static_style([
  ("&", respo_style(display=Grid, gap=Px(18)).add("align-content", "start")),
])

///|
let s_hero_meta : String = contained_static_style([
  (
    None,
    "&",
    respo_style(display=Grid, gap=Px(12), justify_items=End).add(
      "align-content", "start",
    ),
  ),
  (Some("@media (max-width: 920px)"), "&", respo_style(justify_items=Start)),
])

///|
let s_hero_stats : String = static_style([
  (
    "&",
    respo_style(
      min_width=Px(120),
      border_radius=18,
      text_align=Right,
      padding_top=Px(14),
      padding_right=Px(16),
      padding_bottom=Px(14),
      padding_left=Px(16),
      background_color=Rgba(255, 255, 255, 0.72),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(15, 118, 110, 0.12),
      ),
    ),
  ),
])

///|
let s_badge_live : String = static_style([
  (
    "&",
    respo_style(
      font_weight="600",
      border_radius=999,
      padding_top=Px(10),
      padding_right=Px(14),
      padding_bottom=Px(10),
      padding_left=Px(14),
      border=@css.CssBorder::new(width=1, style=Solid, color=Rgba(0, 0, 0, 0)),
    )
    .add("background", "var(--accent-soft)")
    .add("color", "var(--accent)"),
  ),
])

///|
let s_badge_connecting : String = static_style([
  (
    "&",
    respo_style(
      font_weight="600",
      border_radius=999,
      padding_top=Px(10),
      padding_right=Px(14),
      padding_bottom=Px(10),
      padding_left=Px(14),
      border=@css.CssBorder::new(width=1, style=Solid, color=Rgba(0, 0, 0, 0)),
      background_color=Rgba(201, 138, 37, 0.14),
      color=Hex(0x94, 0x62, 0x00),
    ),
  ),
])

///|
let s_badge_closed : String = static_style([
  (
    "&",
    respo_style(
      font_weight="600",
      border_radius=999,
      padding_top=Px(10),
      padding_right=Px(14),
      padding_bottom=Px(10),
      padding_left=Px(14),
      border=@css.CssBorder::new(width=1, style=Solid, color=Rgba(0, 0, 0, 0)),
    )
    .add("background", "var(--danger-soft)")
    .add("color", "var(--danger)"),
  ),
])

///|
let s_tabs : String = static_style([
  ("&", respo_style(display=Flex, gap=Px(10)).add("flex-wrap", "wrap")),
])

///|
let s_field : String = static_style([
  (
    "&",
    respo_style(
      display=Grid,
      gap=Px(8),
      margin_top=Px(14),
      margin_bottom=Px(14),
    ),
  ),
  (
    "& input",
    respo_style(
      width=Percent(100),
      border_radius=16,
      padding_top=Px(14),
      padding_right=Px(15),
      padding_bottom=Px(14),
      padding_left=Px(15),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.14),
      ),
      background_color=Rgba(255, 255, 255, 0.92),
    ).add("color", "var(--text)"),
  ),
])

///|
let s_feature_grid : String = static_style([
  (
    "&",
    respo_style(
      display=Grid,
      gap=Px(14),
      grid_template_columns=Custom("repeat(auto-fit, minmax(180px, 1fr))"),
    ),
  ),
  (
    "& > *",
    respo_style(
      border_radius=18,
      padding=Px(16),
      background_color=Rgba(255, 255, 255, 0.74),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.08),
      ),
    ),
  ),
  (
    "& h3",
    respo_style(
      font_size=16,
      margin_top=Px(0),
      margin_right=Px(0),
      margin_bottom=Px(10),
      margin_left=Px(0),
    ),
  ),
])

///|
let s_member_grid : String = static_style([
  (
    "&",
    respo_style(
      display=Grid,
      gap=Px(14),
      grid_template_columns=Custom("repeat(auto-fit, minmax(180px, 1fr))"),
    ),
  ),
])

///|
let s_member_card : String = static_style([
  (
    "&",
    respo_style(
      border_radius=18,
      padding=Px(16),
      background_color=Rgba(255, 255, 255, 0.74),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.08),
      ),
    ),
  ),
  (
    "& h3",
    respo_style(
      font_size=16,
      margin_top=Px(0),
      margin_right=Px(0),
      margin_bottom=Px(10),
      margin_left=Px(0),
    ),
  ),
])

///|
let s_bulletin_list : String = static_style([
  ("&", respo_style(display=Grid, gap=Px(12))),
])

///|
let s_bulletin_composer : String = static_style([
  ("&", respo_style(display=Grid, gap=Px(12), margin_bottom=Px(18))),
])

///|
let s_board_header : String = static_style([
  (
    "&",
    respo_style(
      display=Flex,
      justify_content=SpaceBetween,
      align_items=FlexEnd,
      gap=Px(16),
      margin_bottom=Px(16),
    ),
  ),
])

///|
let s_bulletin_card : String = static_style([
  (
    "&",
    respo_style(
      display=Grid,
      gap=Px(8),
      border_radius=18,
      padding=Px(16),
      background_color=Rgba(255, 255, 255, 0.74),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(31, 41, 51, 0.08),
      ),
    ),
  ),
])

///|
let s_eyebrow : String = static_style([
  (
    "&",
    respo_style(
      font_size=12,
      letter_spacing="0.18em",
      margin_top=Px(0),
      margin_bottom=Px(0),
      text_transform="uppercase",
    ).add("color", "var(--accent)"),
  ),
])

///|
let s_board_count : String = static_style([
  ("&", respo_style(font_weight="600").add("color", "var(--accent)")),
])

///|
let s_board_note : String = static_style([
  ("&", respo_style(margin_top=Px(0), margin_bottom=Px(16))),
])

///|
let s_bulletin_meta : String = static_style([
  (
    "&",
    respo_style(
      letter_spacing="0.12em",
      margin_top=Px(0),
      margin_bottom=Px(0),
      text_transform="uppercase",
    )
    .add("font-size", "0.78rem")
    .add("color", "var(--muted)"),
  ),
])

///|
let s_bulletin_text : String = static_style([
  (
    "&",
    respo_style(margin_top=Px(0), margin_bottom=Px(0), line_height=Em(1.6)).add(
      "color", "var(--text)",
    ),
  ),
])

///|
let s_nav_user : String = contained_static_style([
  (
    None,
    "&",
    respo_style(padding_right=Px(8), margin_left=Auto).add(
      "color", "var(--muted)",
    ),
  ),
  (
    Some("@media (max-width: 920px)"),
    "&",
    respo_style(margin_left=Px(0), width=Percent(100)),
  ),
])

///|
let s_toast_title : String = static_style([
  ("&", respo_style(display=Block, margin_bottom=Px(6), margin_top=Px(0))),
])

///|
let s_toast_info : String = static_style([
  (
    "&",
    respo_style(
      display=Flex,
      justify_content=SpaceBetween,
      align_items=FlexStart,
      gap=Px(12),
      border_radius=18,
      margin_bottom=Px(12),
      padding_top=Px(16),
      padding_right=Px(18),
      padding_bottom=Px(16),
      padding_left=Px(18),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(15, 118, 110, 0.18),
      ),
    ).add("background", "var(--accent-soft)"),
  ),
  ("& p", respo_style(margin_top=Px(0), margin_bottom=Px(0))),
])

///|
let s_toast_error : String = static_style([
  (
    "&",
    respo_style(
      display=Flex,
      justify_content=SpaceBetween,
      align_items=FlexStart,
      gap=Px(12),
      border_radius=18,
      margin_bottom=Px(12),
      padding_top=Px(16),
      padding_right=Px(18),
      padding_bottom=Px(16),
      padding_left=Px(18),
      border=@css.CssBorder::new(
        width=1,
        style=Solid,
        color=Rgba(191, 77, 40, 0.18),
      ),
    ).add("background", "var(--danger-soft)"),
  ),
  ("& p", respo_style(margin_top=Px(0), margin_bottom=Px(0))),
])

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
    Open => s_badge_live
    Connecting => s_badge_connecting
    Closed => s_badge_closed
  }
}

///|
fn render_messages(
  messages : Array[@shared.FlashMessage],
) -> Array[RespoNode[ActionOp, Unit]] {
  let items = Array::new(capacity=messages.length())
  for message in messages {
    let toast_class = match message.kind {
      Info => s_toast_info
      Error => s_toast_error
    }
    let title = match message.kind {
      Info => "Info"
      Error => "Error"
    }
    items.push(
      div(class_name=toast_class, [
        div([
          span(class_name=s_toast_title, inner_text=title, []),
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
fn render_members(
  members : Array[@shared.MemberView],
) -> Array[RespoNode[ActionOp, Unit]] {
  let items = Array::new(capacity=members.length())
  for person in members {
    items.push(
      div(class_name=s_member_card, [
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
) -> Array[RespoNode[ActionOp, Unit]] {
  if bulletins.length() == 0 {
    return [
      div(class_name=s_bulletin_card, [p(inner_text="No bulletins yet.", [])]),
    ]
  }
  let items = Array::new(capacity=bulletins.length())
  for bulletin in bulletins {
    items.push(
      div(class_name=s_bulletin_card, [
        p(class_name=s_bulletin_meta, inner_text=bulletin.author, []),
        p(class_name=s_bulletin_text, inner_text=bulletin.text, []),
      ]),
    )
  }
  items
}

///|
fn render_auth_panel(store : Store) -> RespoNode[ActionOp, Unit] {
  match store.remote.current_user {
    Some(user) =>
      div(class_list=["panel", "auth-panel"], [
        p(class_name=s_eyebrow, inner_text="Current session", []),
        h2(inner_text=user.name, []),
        p(inner_text="session: \{store.remote.session_id}", []),
        p(inner_text="connection: \{connection_label(store.ui.connection)}", []),
        div(class_name=s_tabs, [
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
        p(class_name=s_eyebrow, inner_text="Account", []),
        div(class_name=s_tabs, [
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
        div(class_name=s_field, [
          span(inner_text="Username", []),
          input(
            value=store.ui.username,
            placeholder="demo",
            on_input=on_input_action(fn(value) { UpdateUsername(value) }),
          ),
        ]),
        div(class_name=s_field, [
          span(inner_text="Password", []),
          input(
            value=store.ui.password,
            placeholder="demo",
            attrs={ "type": "password" },
            on_input=on_input_action(fn(value) { UpdatePassword(value) }),
          ),
        ]),
        div(class_name=s_tabs, [
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
fn render_home(store : Store) -> RespoNode[ActionOp, Unit] {
  let bulletins = render_bulletins(store.remote.bulletins)
  let composer = if store.remote.logged_in {
    [
      div(class_name=s_bulletin_composer, [
        div(class_name=s_field, [
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
        class_name=s_board_note,
        inner_text="Log in to post on the shared bulletin board. Other tabs will receive the update as a delta.",
        [],
      ),
    ]
  }
  div([
    div(class_list=["panel", "content-panel"], [
      p(class_name=s_eyebrow, inner_text="Home", []),
      h2(inner_text="How this mirrors Cumulo", []),
      div(class_name=s_feature_grid, [
        div([
          h3(inner_text="Authoritative server", []),
          p(
            inner_text="The server keeps the full AppDb and applies a pure updater for every client operation.",
            [],
          ),
        ]),
        div([
          h3(inner_text="Session twig", []),
          p(
            inner_text="Each WebSocket client receives a filtered ClientView, not the raw database.",
            [],
          ),
        ]),
        div([
          h3(inner_text="Diff over WebSocket", []),
          p(
            inner_text="After the first snapshot, later changes go out as structural patches built by diff_value.",
            [],
          ),
        ]),
      ]),
    ]),
    div(class_list=["panel", "content-panel"], [
      div(class_name=s_board_header, [
        div([
          p(class_name=s_eyebrow, inner_text="Bulletin board", []),
          h2(inner_text="Shared demo state", []),
        ]),
        span(
          class_name=s_board_count,
          inner_text="\{store.remote.bulletins.length()} posts",
          [],
        ),
      ]),
      p(
        class_name=s_board_note,
        inner_text="Use this to verify that one page can mutate shared state and every other page patches into the new projection.",
        [],
      ),
      div(composer + [div(class_name=s_bulletin_list, bulletins)]),
    ]),
  ])
}

///|
fn render_members_route(store : Store) -> RespoNode[ActionOp, Unit] {
  div(class_list=["panel", "content-panel"], [
    p(class_name=s_eyebrow, inner_text="Members", []),
    h2(inner_text="Known users", []),
    div(class_name=s_member_grid, render_members(store.remote.members)),
  ])
}

///|
fn view(store : Store) -> RespoNode[ActionOp, Unit] {
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
          p(class_name=s_eyebrow, inner_text="MoonBit + Cumulo", []),
          h1(inner_text="Realtime fullstack patch sync", []),
          p(class_name="lead", inner_text=store.remote.welcome, []),
        ]),
        div(
          class_name=s_hero_meta,
          [
            span(
              class_name=connection_class(store.ui.connection),
              inner_text=connection_label(store.ui.connection),
              [],
            ),
            div(class_name=s_hero_stats, [
              text_node(store.remote.viewer_count.to_string()),
              span(inner_text="viewers", []),
            ]),
            div(class_name=s_hero_stats, [
              text_node(store.remote.member_count.to_string()),
              span(inner_text="users", []),
            ]),
          ] +
          reconnect_nodes,
        ),
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
        span(class_name=s_nav_user, inner_text="viewer: \{viewer}", []),
      ]),
      div(class_name=s_layout, [
        div(class_name=s_column_gap, [
          render_auth_panel(store),
          div(class_list=["panel", "tips"], [
            p(class_name=s_eyebrow, inner_text="Transport", []),
            p(
              inner_text="Snapshot on connect. Delta patches afterwards. The browser applies patches to a typed ClientView.",
              [],
            ),
          ]),
        ]),
        div(class_name=s_column_gap, [
          div(render_messages(store.remote.messages)),
          route_node,
        ]),
      ]),
    ],
  )
}
