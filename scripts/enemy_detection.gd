@tool
class_name EnemyDetection
extends Node3D

const CIRCLE_SEGMENTS: int = 96

@export var radius: float = 12.32:
  set(value):
    radius = maxf(value, 0.0)
    if _circle != null:
      _draw_circle()

var _circle: ImmediateMesh


func _ready() -> void:
  if not Engine.is_editor_hint():
    return

  _circle = ImmediateMesh.new()
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = Color(1.0, 0.5, 0.25)

  var preview := MeshInstance3D.new()
  preview.mesh = _circle
  preview.material_override = material
  preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(preview, false, Node.INTERNAL_MODE_BACK)
  _draw_circle()


func detects(world_position: Vector3) -> bool:
  return global_position.distance_squared_to(world_position) <= radius * radius


func _draw_circle() -> void:
  _circle.clear_surfaces()
  _circle.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
  for segment: int in range(CIRCLE_SEGMENTS + 1):
    var angle: float = TAU * segment / CIRCLE_SEGMENTS
    _circle.surface_add_vertex(Vector3(cos(angle) * radius, 0.04, sin(angle) * radius))
  _circle.surface_end()
