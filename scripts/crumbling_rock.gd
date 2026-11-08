class_name CrumblingRock
extends StaticBody3D

@export var sprite: Sprite3D
@export var flash_shader: Shader
@export var crumble_scene: PackedScene
@export var hit_flash_duration: float = 0.08

var _crumbled: bool = false


func take_shot() -> void:
  if _crumbled:
    return
  _crumbled = true
  collision_layer = 0
  collision_mask = 0
  var flash := ShaderMaterial.new()
  flash.shader = flash_shader
  flash.set_shader_parameter('rock_texture', sprite.texture)
  sprite.material_override = flash
  var tween := create_tween()
  tween.tween_interval(hit_flash_duration)
  tween.tween_callback(_crumble)


func _crumble() -> void:
  var dust := crumble_scene.instantiate() as CPUParticles3D
  dust.transform = transform
  get_parent().add_child(dust)
  sprite.hide()
  queue_free()
