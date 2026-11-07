class_name CrumblingRock
extends StaticBody3D

@export var sprite: Sprite3D
@export var crumble_scene: PackedScene
@export var hit_flash_duration: float = 0.08

var _crumbled: bool = false


func take_shot() -> void:
  if _crumbled:
    return
  _crumbled = true
  collision_layer = 0
  collision_mask = 0
  var flash := sprite.material_override.duplicate() as StandardMaterial3D
  flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  flash.normal_enabled = false
  flash.albedo_color = Color.WHITE
  flash.emission_enabled = true
  flash.emission = Color.WHITE
  flash.emission_energy_multiplier = 16.0
  # keep the sprite's texture alpha so only the rock silhouette flashes.
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
