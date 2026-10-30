extends Control

signal handling_changed(handling: bool)
signal ball_requested
signal ramrod_requested(event: InputEvent)

@export var musket: Musket
@export var lantern: Lantern
@export var hover_offset: Control
@export var lit_offset: Control
@export var reaction: Control
@export var ball_motion: Control
@export var ramrod: Control
@export var detach: Control
@export var drag: Control
@export var chamber: Marker2D
@export var barrel_target: Control
@export var ramrod_target: Control
@export var tucked_distance: float = 165.0
@export var detach_distance: float = 65.0
@export var ramrod_travel: float = 150.0
@export var lift_duration: float = 0.22
@export var ball_duration: float = 0.4

var _hovered: bool = false
var _handling: bool = false
var _dragging: bool = false
var _busy: bool = false
var _last_state: Musket.ReloadState
var _last_insertion: float = 0.0
var _hover_tween: Tween
var _detach_tween: Tween
var _lit_tween: Tween
var _ball_tween: Tween
var _rod_tween: Tween
var _reaction_tween: Tween


func _ready() -> void:
  hover_offset.position.y = tucked_distance
  _last_state = musket.reload_state
  musket.equipped.connect(_refresh)
  musket.unequipped.connect(_refresh)
  musket.aiming_changed.connect(_refresh)
  lantern.carried_changed.connect(_refresh)
  musket.lit_changed.connect(_refresh)
  musket.reload_changed.connect(_on_reload_changed)
  ball_motion.visible = musket.reload_state != Musket.ReloadState.EMPTY
  _refresh()


func _can_interact() -> bool:
  return musket.is_owned and not musket.is_aiming and not lantern.is_carried and not musket.is_lit


func _refresh(_changed: bool = false) -> void:
  visible = musket.is_owned
  if _lit_tween:
    _lit_tween.kill()
  _lit_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _lit_tween.tween_property(lit_offset, 'position:x', -70.0 if musket.is_lit or musket.is_aiming else 0.0, lift_duration)
  _move_hover()
  _update_targets()


# the hover rectangle stays still while child click targets and artwork move.
func _process(_delta: float) -> void:
  if not is_visible_in_tree():
    return
  var hovered := get_global_rect().has_point(get_global_mouse_position())
  if _hovered == hovered:
    return
  _hovered = hovered
  _move_hover()


func _move_hover() -> void:
  var raised := _can_interact() and (_hovered or _dragging)
  if _handling != raised:
    _handling = raised
    handling_changed.emit(raised)
  if _hover_tween:
    _hover_tween.kill()
  _hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _hover_tween.tween_property(hover_offset, 'position:y', 0.0 if raised else tucked_distance, lift_duration)
  if not _dragging and not _busy:
    if _detach_tween:
      _detach_tween.kill()
    _detach_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    var detached := raised and musket.can_use_ramrod()
    _detach_tween.tween_property(detach, 'position:x', detach_distance if detached else 0.0, lift_duration)


func _update_targets() -> void:
  var available := _can_interact() and not _busy and not _dragging
  _set_target_enabled(barrel_target, available and musket.reload_state == Musket.ReloadState.EMPTY)
  _set_target_enabled(ramrod_target, available and musket.can_use_ramrod())


func _set_target_enabled(target: Control, enabled: bool) -> void:
  target.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
  target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW


func _on_barrel_input(event: InputEvent) -> void:
  if not event.is_action_pressed('fire_musket'):
    return
  accept_event()
  if _can_interact() and not _busy and musket.reload_state == Musket.ReloadState.EMPTY:
    ball_requested.emit()


func _on_ramrod_input(event: InputEvent) -> void:
  if not event.is_action_pressed('fire_musket'):
    return
  accept_event()
  if _can_interact() and not _busy:
    ramrod_requested.emit(event)


func _on_reload_changed() -> void:
  var state := musket.reload_state
  var state_changed := state != _last_state
  if state == Musket.ReloadState.BALL_INSERTED and _last_state == Musket.ReloadState.EMPTY:
    _load_ball()
  elif state == Musket.ReloadState.LOADED:
    ball_motion.show()
    ball_motion.position = Vector2.ZERO
    ball_motion.modulate.a = 1.0
  elif state == Musket.ReloadState.EMPTY:
    ball_motion.hide()
  if musket.ramrod_insertion == 1.0 and _last_insertion < 1.0:
    _punch()
  _last_insertion = musket.ramrod_insertion
  _last_state = state
  if _dragging:
    _position_rod()
  if state_changed and not _busy:
    _move_hover()
  _update_targets()


func _load_ball() -> void:
  _busy = true
  ball_motion.show()
  ball_motion.position = Vector2.UP * 75.0
  ball_motion.modulate.a = 0.0
  if _ball_tween:
    _ball_tween.kill()
  _ball_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  _ball_tween.tween_property(ball_motion, 'position', Vector2.ZERO, ball_duration)
  _ball_tween.parallel().tween_property(ball_motion, 'modulate:a', 1.0, ball_duration * 0.6)
  _ball_tween.tween_callback(_on_ball_landed)


func _on_ball_landed() -> void:
  _busy = false
  _punch()
  _move_hover()
  _update_targets()


func _on_ramrod_drag_changed(dragging: bool) -> void:
  _dragging = dragging
  if dragging:
    if _detach_tween:
      _detach_tween.kill()
    _position_rod()
  else:
    _return_rod()
  _move_hover()
  _update_targets()


func _position_rod() -> void:
  drag.position = chamber.position - ramrod.position - detach.position + Vector2.DOWN * ramrod_travel * musket.ramrod_insertion


func _return_rod() -> void:
  _busy = true
  if _rod_tween:
    _rod_tween.kill()
  _rod_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  var withdrawn := chamber.position - ramrod.position - detach.position
  _rod_tween.tween_property(drag, 'position', withdrawn, 0.18)
  _rod_tween.tween_property(drag, 'position', Vector2.ZERO, 0.22)
  _rod_tween.tween_callback(_on_rod_returned)


func _on_rod_returned() -> void:
  _busy = false
  _move_hover()
  _update_targets()


func _punch() -> void:
  if _reaction_tween:
    _reaction_tween.kill()
  _reaction_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  _reaction_tween.tween_property(reaction, 'scale', Vector2.ONE * 0.94, 0.06)
  _reaction_tween.parallel().tween_property(reaction, 'rotation', deg_to_rad(randf_range(-2.0, 2.0)), 0.06)
  _reaction_tween.tween_property(reaction, 'scale', Vector2.ONE, 0.18)
  _reaction_tween.parallel().tween_property(reaction, 'rotation', 0.0, 0.18)
