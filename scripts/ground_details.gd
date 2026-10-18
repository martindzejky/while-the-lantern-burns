class_name GroundDetails
extends Node3D

@export var cracks: Array[Texture2D] = []
@export var stones: Array[Texture2D] = []
@export var stone_normals: Array[Texture2D] = []
@export var patch_material: ShaderMaterial
@export var stone_material: ShaderMaterial
@export var seed_value: int = 60
@export_range(0.0, 2.0, 0.01) var crack_density: float = 0.12
@export_range(0.0, 2.0, 0.01) var stone_density: float = 0.22
@export var crack_width: Vector2 = Vector2(0.5, 1.6)
@export var stone_width: Vector2 = Vector2(0.12, 0.38)
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.8
@export_range(0.0, 1.0, 0.01) var edge_margin: float = 0.12
# clearance above the upper face, whichever direction the floor is rotated.
@export var surface_offset: float = 0.001

var _surface_z: float = 0.0


func generate(polygon: PackedVector2Array, ground_depth: float = 0.01) -> void:
  _surface_z = surface_offset if global_basis.z.y >= 0.0 else -ground_depth - surface_offset
  for child: Node in get_children():
    remove_child(child)
    child.queue_free()
  if polygon.size() < 3:
    return
  var bounds := Rect2(polygon[0], Vector2.ZERO)
  var twice_area: float = 0.0
  for index: int in range(polygon.size()):
    bounds = bounds.expand(polygon[index])
    twice_area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
  var area: float = absf(twice_area) * 0.5
  var random := RandomNumberGenerator.new()
  random.seed = seed_value
  _scatter(cracks, roundi(area * crack_density), crack_width, polygon, bounds, random, 'crack')
  assert(stone_normals.size() == stones.size(), 'Each ground stone needs its matching normal map')
  _scatter(stones, roundi(area * stone_density), stone_width, polygon, bounds, random, 'stone', stone_normals)


func _scatter(textures: Array[Texture2D], count: int, widths: Vector2, polygon: PackedVector2Array, bounds: Rect2, random: RandomNumberGenerator, prefix: String, normal_textures: Array[Texture2D] = []) -> void:
  if textures.is_empty():
    return
  var placed: int = 0
  for attempt: int in range(count * 20):
    if placed >= count:
      break
    var variant: int = random.randi_range(0, textures.size() - 1)
    var texture: Texture2D = textures[variant]
    var width: float = random.randf_range(widths.x, widths.y)
    var size := Vector2(width, width * float(texture.get_height()) / float(texture.get_width()))
    var point := Vector2(random.randf_range(bounds.position.x, bounds.end.x), random.randf_range(bounds.position.y, bounds.end.y))
    # a containing circle keeps every rotated corner inside even concave outlines.
    if not _fits(point, size.length() * 0.5 + edge_margin, polygon):
      continue
    var mesh := QuadMesh.new()
    mesh.size = size
    var is_stone: bool = not normal_textures.is_empty()
    if is_stone:
      # bury a little of the rounded bottom to keep contact with the ground.
      mesh.center_offset.y = size.y * 0.35
    var material := (stone_material if is_stone else patch_material).duplicate() as ShaderMaterial
    material.set_shader_parameter('detail_texture', texture)
    if is_stone:
      material.set_shader_parameter('detail_normal', normal_textures[variant])
    else:
      material.set_shader_parameter('opacity', opacity)
    var patch := MeshInstance3D.new()
    patch.name = '%s_%03d' % [prefix, placed + 1]
    patch.mesh = mesh
    patch.material_override = material
    patch.position = Vector3(point.x, point.y, _surface_z)
    var angle := random.randf_range(-PI, PI)
    patch.rotation.z = angle if normal_textures.is_empty() else 0.0
    patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    # exclude decoration from the light sensor camera, like the drop shadows.
    patch.layers = 4
    add_child(patch)
    placed += 1


func _fits(point: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
  if not Geometry2D.is_point_in_polygon(point, polygon):
    return false
  for index: int in range(polygon.size()):
    var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])
    if point.distance_squared_to(closest) < radius * radius:
      return false
  return true
