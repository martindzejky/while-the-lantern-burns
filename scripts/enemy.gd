class_name Enemy
extends CharacterBody3D

@export var target: Player
@export var appearance: Node3D
@export var head: Node3D
@export var head_sprite: Sprite3D
@export var body: Sprite3D
@export var eyes: Sprite3D
@export var mouth: Node3D
@export var upper_teeth: Sprite3D
@export var lower_teeth: Sprite3D
@export var animation: AnimationPlayer
@export var head_textures: Array[Texture2D]
@export var body_textures: Array[Texture2D]
@export var eye_textures: Array[Texture2D]
@export var head_variant: int = -1
@export var body_variant: int = -1
@export var eye_variant: int = -1
@export var preview: bool = false
@export_range(0.0, 0.25) var size_variation: float = 0.1
@export var speed: float = 0.8
@export var bite_range: float = 1.15
@export var head_bob_height: float = 0.025
@export_range(1.0, 10.0, 0.5) var head_bob_period: float = 3.0

var _biting: bool = false
var _head_base_y: float
var _head_bob_phase: float
var _head_bob_offset: float = 0.0


func _ready() -> void:
  _set_appearance()
  _head_base_y = head.position.y
  _head_bob_phase = randf() * TAU
  if preview:
    set_physics_process(false)


func _process(delta: float) -> void:
  if _biting:
    _head_bob_offset = 0.0
  elif preview or not velocity.is_zero_approx():
    _head_bob_phase += delta * TAU / head_bob_period
    _head_bob_offset = sin(_head_bob_phase) * head_bob_height
  else:
    _head_bob_offset = move_toward(_head_bob_offset, 0.0, delta * head_bob_height)
  head.position.y = _head_base_y + _head_bob_offset


func _set_appearance() -> void:
  head_sprite.texture = _pick_texture(head_textures, head_variant)
  body.texture = _pick_texture(body_textures, body_variant)
  eyes.texture = _pick_texture(eye_textures, eye_variant)
  appearance.scale = Vector3.ONE * randf_range(1.0 - size_variation, 1.0 + size_variation)
  var body_height := body.texture.get_height() * body.pixel_size
  var head_height := head_sprite.texture.get_height() * head_sprite.pixel_size
  body.offset.y = body.texture.get_height() * 0.5
  head_sprite.offset.y = head_sprite.texture.get_height() * 0.5
  head.position.y = body_height - head_height * 0.4
  eyes.position.y = head_height * 0.52
  mouth.position.y = head.position.y + head_height * 0.15
  var mouth_width := minf(
    body.texture.get_width() * body.pixel_size,
    head_sprite.texture.get_width() * head_sprite.pixel_size
  ) * 0.8
  upper_teeth.pixel_size = mouth_width / upper_teeth.texture.get_width()
  lower_teeth.pixel_size = mouth_width / lower_teeth.texture.get_width()
  var tooth_height := upper_teeth.texture.get_height() * upper_teeth.pixel_size
  upper_teeth.position.y = tooth_height * 0.35
  lower_teeth.position.y = -tooth_height * 0.35


func _pick_texture(textures: Array[Texture2D], variant: int) -> Texture2D:
  return textures[variant if variant >= 0 else randi_range(0, textures.size() - 1)]


func _physics_process(_delta: float) -> void:
  velocity = Vector3.ZERO
  if target.is_dead or _biting:
    return
  if _within_bite_range():
    bite()
  else:
    velocity = global_position.direction_to(target.global_position) * speed
    move_and_slide()


func take_shot() -> void:
  set_physics_process(false)
  animation.stop()
  collision_layer = 0
  hide()
  queue_free()


func _within_bite_range() -> bool:
  return global_position.distance_squared_to(target.global_position) <= bite_range * bite_range


func bite() -> void:
  if _biting or is_queued_for_deletion():
    return
  _biting = true
  animation.play('bite')


func _bite() -> void:
  if is_queued_for_deletion():
    return
  if not preview and not target.is_dead and _within_bite_range():
    target.take_bite()


func _on_animation_finished(_animation_name: StringName) -> void:
  _biting = false
