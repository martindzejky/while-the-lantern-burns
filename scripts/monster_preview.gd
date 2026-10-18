extends Node3D

@export var camera: Camera3D

var _click_requested: bool = false
var _click_position: Vector2


func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
    _click_position = event.position
    _click_requested = true
    get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
  if not _click_requested:
    return
  _click_requested = false
  var origin := camera.project_ray_origin(_click_position)
  var end := origin + camera.project_ray_normal(_click_position) * 100.0
  var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
  var hit := get_world_3d().direct_space_state.intersect_ray(query)
  var enemy := hit.get('collider') as Enemy
  if enemy:
    enemy.bite()
