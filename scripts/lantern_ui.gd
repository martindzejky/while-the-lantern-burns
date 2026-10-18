extends Control

signal charge_requested

@export var lantern: Lantern
@export var hover_offset: Control
@export var reaction: Control
@export var lever: Control
@export var tucked_distance: float = 145.0
@export var lift_duration: float = 0.22
@export var squeeze_angle: float = -55.0

var _hovered: bool = false
var _lever_rest: float
var _hover_tween: Tween
var _reaction_tween: Tween


func _ready() -> void:
  _lever_rest = lever.rotation
  hover_offset.position.y = tucked_distance
  lantern.carried_changed.connect(_on_carried_changed)
  lantern.lever_changed.connect(_on_lever_changed)
  _on_carried_changed(lantern.is_carried)
  _on_lever_changed(lantern.lever_openness)


func _on_carried_changed(carried: bool) -> void:
  visible = carried
  if not carried:
    _hovered = false
    _move_hover()


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
  if _hover_tween:
    _hover_tween.kill()
  _hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _hover_tween.tween_property(hover_offset, 'position:y', 0.0 if _hovered else tucked_distance, lift_duration)


func _on_click_input(event: InputEvent) -> void:
  if not event.is_action_pressed('wind_lantern') or not lantern.is_carried:
    return
  accept_event()
  charge_requested.emit()
  if _reaction_tween:
    _reaction_tween.kill()
  _reaction_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  _reaction_tween.tween_property(reaction, 'scale', Vector2.ONE * 0.9, 0.07)
  _reaction_tween.parallel().tween_property(reaction, 'rotation', deg_to_rad(randf_range(-3.0, 3.0)), 0.07)
  _reaction_tween.tween_property(reaction, 'scale', Vector2.ONE, 0.18)
  _reaction_tween.parallel().tween_property(reaction, 'rotation', 0.0, 0.18)


func _on_lever_changed(openness: float) -> void:
  lever.rotation = _lever_rest + deg_to_rad(squeeze_angle) * (1.0 - openness)
