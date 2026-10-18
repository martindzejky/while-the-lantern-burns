class_name DropShadow
extends Sprite3D

# visual layer 3 keeps these circles out of the light sensor camera.
@export var anchor: Node3D
@export var light_source: Node3D
@export var ground_height: float = 0.012
@export var offset_per_unit: float = 0.04
@export var maximum_offset: float = 0.16


func _process(_delta: float) -> void:
  if not is_visible_in_tree():
    return
  var floor_position := anchor.global_position
  floor_position.y = ground_height
  if is_instance_valid(light_source):
    var away := anchor.global_position - light_source.global_position
    away.y = 0.0
    floor_position += (away * offset_per_unit).limit_length(maximum_offset)
  global_position = floor_position


func set_carried(carried: bool) -> void:
  visible = not carried
