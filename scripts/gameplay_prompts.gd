extends Control

@export var player: Player
@export var lantern: Lantern
@export var musket: Musket
@export var movement: Label3D
@export var instruction: Label
@export var context: Label3D

var _refresh_timer: Timer = Timer.new()
var _hud_layer: CanvasLayer
var _start_position: Vector3
var _has_moved: bool = false
var _has_charged: bool = false
var _has_picked_lantern: bool = false
var _has_picked_musket: bool = false
var _has_dropped_lantern: bool = false
var _has_inserted_ball: bool = false
var _has_loaded: bool = false
var _has_lit: bool = false
var _has_aimed: bool = false
var _has_fired: bool = false
var _was_carrying: bool = false


func _ready() -> void:
  _hud_layer = get_canvas_layer_node()
  _hud_layer.visibility_changed.connect(_on_visibility_changed)
  _start_position = player.global_position
  movement.global_position = _start_position + Vector3(0, 2.4, 0)
  lantern.lever_changed.connect(_on_lever_changed)
  musket.fired.connect(_on_musket_fired)
  visibility_changed.connect(_on_visibility_changed)
  _refresh_timer.wait_time = 0.12
  _refresh_timer.timeout.connect(_refresh)
  add_child(_refresh_timer)
  _refresh_timer.start()
  _refresh()


func _on_lever_changed(openness: float) -> void:
  if openness < 0.1 and lantern.is_carried:
    _has_charged = true


func _on_musket_fired(_hit: Dictionary) -> void:
  _has_fired = true


func _on_visibility_changed() -> void:
  if not is_visible_in_tree() or not _hud_layer.visible:
    movement.hide()
    context.hide()


func _refresh() -> void:
  visible = not player.is_dead and player.process_mode != Node.PROCESS_MODE_DISABLED and _hud_layer.visible
  if not visible:
    movement.hide()
    context.hide()
    return
  if player.global_position.distance_squared_to(_start_position) > 1.0:
    _has_moved = true
  _has_picked_lantern = _has_picked_lantern or lantern.is_carried
  _has_picked_musket = _has_picked_musket or musket.is_owned
  _has_dropped_lantern = _has_dropped_lantern or (_was_carrying and not lantern.is_carried)
  _was_carrying = lantern.is_carried
  _has_inserted_ball = _has_inserted_ball or musket.reload_state != Musket.ReloadState.EMPTY
  _has_loaded = _has_loaded or musket.reload_state == Musket.ReloadState.LOADED
  _has_lit = _has_lit or musket.is_lit
  _has_aimed = _has_aimed or (musket.is_lit and musket.is_aiming)
  movement.visible = not _has_moved and is_visible_in_tree()
  instruction.text = _get_instruction()
  instruction.visible = not instruction.text.is_empty()
  var on_right: bool = lantern.is_carried
  instruction.anchor_left = 0.56 if on_right else 0.14
  instruction.anchor_right = 0.86 if on_right else 0.44
  context.text = _get_context()
  context.visible = not context.text.is_empty() and is_visible_in_tree()


func _near(item: Node3D) -> bool:
  return player.global_position.distance_squared_to(item.global_position) <= player.pickup_radius * player.pickup_radius


func _get_context() -> String:
  if musket.is_trigger_pending:
    return ''
  if lantern.is_carried:
    context.global_position = player.global_position + Vector3(0, 2.4, 0)
    if not musket.is_owned and _near(musket):
      return 'E / ENTER\nPut down the lantern first'
    if musket.is_owned and not _has_dropped_lantern:
      return 'E / ENTER\nPut down the lantern'
    return ''
  if not musket.is_owned and not _has_picked_musket and _near(musket):
    context.global_position = musket.global_position + Vector3(0, 1.3, 0)
    return 'E / ENTER\nPick up the musket'
  if not musket.is_lit and _near(lantern):
    context.global_position = lantern.global_position + Vector3(0, 1.5, 0)
    if musket.is_owned and musket.reload_state == Musket.ReloadState.LOADED and not _has_lit:
      if lantern.energy >= lantern.max_energy * 0.2:
        return 'R / SHIFT / SPACE\nLight the fuse'
      return 'Pick up and charge the lantern first'
    if not _has_picked_lantern:
      return 'E / ENTER\nPick up the lantern'
  return ''


func _get_instruction() -> String:
  if musket.is_lit:
    if not _has_aimed:
      return 'Hold RIGHT MOUSE to aim'
    if not _has_fired:
      return 'LEFT CLICK to fire'
    return ''
  if lantern.is_carried:
    if not _has_charged:
      return 'Hover over the lantern\nCLICK the handle to charge it'
    return ''
  if musket.is_owned:
    match musket.reload_state:
      Musket.ReloadState.EMPTY:
        if not _has_inserted_ball:
          return 'Hover over the musket\nCLICK the barrel opening'
      Musket.ReloadState.BALL_INSERTED:
        if not _has_loaded:
          return 'HOLD the rod and DRAG DOWN\nPush it to the bottom of the barrel'
      Musket.ReloadState.LOADED:
        if not _has_lit:
          return 'Stand beside your charged lantern\nPut it down to light the fuse'
  return ''
