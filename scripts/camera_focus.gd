@tool
class_name CameraFocus
extends Area3D

signal focus_entered(focus: CameraFocus, body: Node3D)
signal focus_exited(focus: CameraFocus, body: Node3D)

@export var shape: CollisionShape3D
@export_range(0.5, 100.0, 0.5) var outer_radius: float = 8.0:
  set(value):
    outer_radius = maxf(value, 0.5)
    _update_shape()
@export_range(0.0, 100.0, 0.5) var inner_radius: float = 3.0


func _ready() -> void:
  _update_shape()


func get_weight(world_position: Vector3) -> float:
  var offset: Vector3 = world_position - global_position
  var distance: float = Vector2(offset.x, offset.z).length()
  return 1.0 - smoothstep(clampf(inner_radius, 0.0, outer_radius - 0.01), outer_radius, distance)


func _update_shape() -> void:
  if not is_node_ready():
    return
  var cylinder: CylinderShape3D = shape.shape as CylinderShape3D
  cylinder.radius = outer_radius


func _on_body_entered(body: Node3D) -> void:
  if not Engine.is_editor_hint():
    focus_entered.emit(self, body)


func _on_body_exited(body: Node3D) -> void:
  if not Engine.is_editor_hint():
    focus_exited.emit(self, body)
