@tool
class_name RandomBigRock
extends Node3D

@export var rock_scenes: Array[PackedScene] = []
@export var seed_value: int = 60
@export var scale_range: Vector2 = Vector2(0.8, 1.5)
@export var height_range: Vector2 = Vector2(0.9, 1.2)
@export_tool_button('Generate') var generate_button: Callable = generate


func _ready() -> void:
  if get_child_count() == 0:
    generate()


func generate() -> void:
  if rock_scenes.is_empty():
    return
  for child: Node in get_children():
    if child.has_meta('random_big_rock_generated'):
      remove_child(child)
      child.queue_free()
  var random := RandomNumberGenerator.new()
  random.seed = seed_value
  var rock := rock_scenes[random.randi_range(0, rock_scenes.size() - 1)].instantiate() as StaticBody3D
  rock.name = 'rock'
  var size: float = random.randf_range(scale_range.x, scale_range.y)
  rock.scale = Vector3(size, size * random.randf_range(height_range.x, height_range.y), size)
  rock.set_meta('random_big_rock_generated', true)
  add_child(rock)
  # previews in the template scene must not become inherited rocks
  rock.owner = owner


func get_footprint_radius() -> float:
  for child: Node in get_children():
    if not child.has_meta('random_big_rock_generated'):
      continue
    var rock := child as StaticBody3D
    for part: Node in rock.get_children():
      var collision := part as CollisionShape3D
      if collision != null and collision.shape is CylinderShape3D:
        var cylinder := collision.shape as CylinderShape3D
        return cylinder.radius * rock.scale.x
  return 0.5
