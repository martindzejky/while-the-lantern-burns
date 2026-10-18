@tool
extends Node3D

@export var rock_scenes: Array[PackedScene] = []
@export var seed_value: int = 60
@export var count_range: Vector2i = Vector2i(4, 6)
@export var spread: Vector2 = Vector2(2.4, 1.2)
@export var width_range: Vector2 = Vector2(0.45, 0.8)
@export var height_range: Vector2 = Vector2(0.65, 1.5)
@export var collisions_enabled: bool = true
@export_tool_button('New variation') var new_variation: Callable = _reroll
@export_tool_button('Apply settings') var apply_settings: Callable = regenerate


func _ready() -> void:
  regenerate()


func _reroll() -> void:
  seed_value = randi_range(0, 2147483647)
  regenerate()


func regenerate() -> void:
  if not is_node_ready() or rock_scenes.is_empty():
    return
  for child: Node in get_children(true):
    if child.has_meta('stalagmite_cluster_generated'):
      remove_child(child)
      child.queue_free()
  var random := RandomNumberGenerator.new()
  random.seed = seed_value
  var count: int = random.randi_range(maxi(1, count_range.x), maxi(maxi(1, count_range.x), count_range.y))
  for index: int in range(count):
    var rock := rock_scenes[random.randi_range(0, rock_scenes.size() - 1)].instantiate() as StaticBody3D
    rock.name = 'stalagmite_%02d' % (index + 1)
    rock.position = Vector3(
      lerpf(-spread.x * 0.5, spread.x * 0.5, (index + random.randf()) / count),
      0.0,
      random.randf_range(-spread.y * 0.5, spread.y * 0.5)
    )
    var width: float = random.randf_range(width_range.x, width_range.y)
    rock.scale = Vector3(width, random.randf_range(height_range.x, height_range.y), width)
    if not collisions_enabled:
      rock.collision_layer = 0
      rock.collision_mask = 0
    rock.set_meta('stalagmite_cluster_generated', true)
    add_child(rock, false, Node.INTERNAL_MODE_BACK)
