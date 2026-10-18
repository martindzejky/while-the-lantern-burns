@tool
extends Node3D

@export var ground: CSGPolygon3D
@export var rock_scene: PackedScene
@export var exclusions: Array[Node3D] = []
@export var seed_value: int = 60
@export_range(0.05, 1.0, 0.05) var density: float = 0.25
@export var edge_stagger: Vector2 = Vector2(0.15, 0.85)
@export var scale_range: Vector2 = Vector2(0.8, 1.6)
@export_tool_button('Generate edge rocks') var generate_button: Callable = generate


func _ready() -> void:
  if get_child_count() == 0 and ground != null:
    generate()


func generate() -> void:
  if ground == null or rock_scene == null or density <= 0.0:
    return
  for child: Node in get_children():
    if child.has_meta('edge_rock_generated'):
      remove_child(child)
      child.queue_free()
  var polygon: PackedVector2Array = ground.polygon
  var area: float = 0.0
  for index: int in range(polygon.size()):
    area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
  var winding: float = 1.0 if area > 0.0 else -1.0
  var random := RandomNumberGenerator.new()
  random.seed = seed_value
  var spacing: float = 1.0 / density
  var distance: float = random.randf_range(0.0, spacing)
  var count: int = 0
  var floor_transform: Transform3D = ground.global_transform if ground.is_inside_tree() else ground.transform
  var own_transform: Transform3D = global_transform if is_inside_tree() else transform
  var scene_owner: Node = owner if owner != null else self
  for index: int in range(polygon.size()):
    var start: Vector2 = polygon[index]
    var edge: Vector2 = polygon[(index + 1) % polygon.size()] - start
    var length: float = edge.length()
    if length < 0.001:
      continue
    var outward := Vector2(edge.y, -edge.x).normalized() * winding
    while distance < length:
      var point: Vector2 = start + edge * (distance / length)
      distance += spacing * random.randf_range(0.6, 1.5)
      if random.randf() < 0.12:
        continue
      var rock := rock_scene.instantiate() as RandomBigRock
      rock.seed_value = random.randi_range(1, 2147483647)
      rock.scale_range = scale_range
      # keep southern rocks low so they frame the path without hiding the player.
      rock.height_range = Vector2(0.9, 1.25) if outward.y > 0.3 else Vector2(0.3, 0.5)
      rock.name = 'edge_rock_%03d' % count
      rock.set_meta('edge_rock_generated', true)
      add_child(rock)
      rock.owner = scene_owner
      if rock.get_child_count() == 0:
        rock.generate()
      for part: Node in rock.get_children():
        part.owner = scene_owner
      var offset: float = random.randf_range(edge_stagger.x, edge_stagger.y)
      var candidate: Vector2 = point + outward * offset
      var world_position: Vector3 = floor_transform * Vector3(candidate.x, candidate.y, 0.0)
      var excluded: bool = false
      for landmark: Node3D in exclusions:
        var landmark_position: Vector3 = landmark.global_position if landmark.is_inside_tree() else landmark.position
        if world_position.distance_squared_to(landmark_position) < 9.0:
          excluded = true
      if excluded:
        remove_child(rock)
        rock.queue_free()
        continue
      rock.position = own_transform.affine_inverse() * world_position
      count += 1
    distance -= length
