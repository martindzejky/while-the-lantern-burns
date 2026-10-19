@tool
class_name SmallRockCluster
extends Node3D

@export var rock_scenes: Array[PackedScene] = []
@export var ground: CSGPolygon3D
@export var seed_value: int = 60
@export var count_range: Vector2i = Vector2i(3, 5)
@export var radius: float = 0.8
@export var scale_range: Vector2 = Vector2(0.9, 1.8)
@export_tool_button('Generate') var generate_button: Callable = generate


func _ready() -> void:
  if get_child_count() == 0:
    generate()


func generate() -> void:
  if rock_scenes.is_empty():
    return
  for child: Node in get_children():
    if child.has_meta('small_rock_cluster_generated'):
      remove_child(child)
      child.queue_free()
  var random := RandomNumberGenerator.new()
  random.seed = seed_value
  var count: int = random.randi_range(count_range.x, count_range.y)
  var placed: Array[Vector3] = []
  for index: int in range(count):
    var rock := rock_scenes[random.randi_range(0, rock_scenes.size() - 1)].instantiate() as StaticBody3D
    var size: float = random.randf_range(scale_range.x, scale_range.y)
    var candidate := Vector3.ZERO
    var valid: bool = false
    for attempt: int in range(24):
      var angle: float = random.randf() * TAU
      var distance: float = sqrt(random.randf()) * radius
      candidate = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
      valid = _inside_ground(candidate, size)
      for previous: Vector3 in placed:
        if previous.distance_squared_to(candidate) < 0.09:
          valid = false
      if valid:
        break
    if not valid:
      rock.free()
      continue
    placed.append(candidate)
    rock.name = 'rock_%02d' % (index + 1)
    rock.position = candidate
    rock.scale = Vector3(size, size * random.randf_range(0.85, 1.15), size)
    rock.set_meta('small_rock_cluster_generated', true)
    add_child(rock)
    # previews in the template scene must not become inherited rocks
    rock.owner = owner


func _inside_ground(local_position: Vector3, size: float) -> bool:
  if ground == null:
    return true
  var cluster_transform: Transform3D = global_transform if is_inside_tree() else transform
  var floor_transform: Transform3D = ground.global_transform if ground.is_inside_tree() else ground.transform
  var point_3d: Vector3 = floor_transform.affine_inverse() * (cluster_transform * local_position)
  var point := Vector2(point_3d.x, point_3d.y)
  if not Geometry2D.is_point_in_polygon(point, ground.polygon):
    return false
  var margin: float = 0.4 * size * cluster_transform.basis.get_scale().x
  for index: int in range(ground.polygon.size()):
    var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
      point, ground.polygon[index], ground.polygon[(index + 1) % ground.polygon.size()]
    )
    if point.distance_squared_to(closest) < margin * margin:
      return false
  return true
