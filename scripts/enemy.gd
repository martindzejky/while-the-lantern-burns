class_name Enemy
extends CharacterBody3D

signal bite_started(enemy: Enemy)
signal bite_finished(enemy: Enemy)
signal bite_landed(enemy: Enemy)

@export var target: Player
@export var appearance: Node3D
@export var head: Node3D
@export var head_lift: Node3D
@export var head_sprite: Sprite3D
@export var body: Sprite3D
@export var eyes: Sprite3D
@export var mouth: Node3D
@export var upper_teeth: Sprite3D
@export var lower_teeth: Sprite3D
@export var vocal_audio: AudioStreamPlayer3D
@export var growl_stream: AudioStream
@export var bite_stream: AudioStream
@export var death_stream: AudioStream
@export var growl_min_time: float = 8.0
@export var growl_max_time: float = 18.0
@export var footstep_audio: AudioStreamPlayer3D
@export var animation: AnimationPlayer
@export var head_textures: Array[Texture2D]
@export var body_textures: Array[Texture2D]
@export var eye_textures: Array[Texture2D]
@export var head_variant: int = -1
@export var body_variant: int = -1
@export var eye_variant: int = -1
@export var preview: bool = false
@export_range(0.0, 0.25) var size_variation: float = 0.1
@export var speed: float = 0.95
@export var engagement_distance: float = 16.0
@export_group('Bite')
@export var bite_range: float = 2.3
@export_range(0.1, 3.0, 0.05) var bite_windup: float = 0.8
@export_range(0.1, 5.0, 0.1) var lunge_distance: float = 2.0
@export_range(0.1, 20.0, 0.1) var lunge_speed: float = 8.0
@export_range(0.1, 2.0, 0.05) var bite_hit_radius: float = 1.1
@export_group('Appearance')
@export var head_bob_height: float = 0.025
@export_range(1.0, 10.0, 0.5) var head_bob_period: float = 3.0
@export var hit_flash_duration: float = 0.3
@export var head_collapse_distance: float = 0.45

var _dead: bool = false
var _engaged: bool = false
var _growl_timer: RandomTimer
var _biting: bool = false
var _head_base_y: float
var _head_bob_phase: float
var _head_bob_offset: float = 0.0
var _bite_impact_time: float
var _lunge_start_time: float
var _lunging: bool = false
var _lunge_remaining: float = 0.0
var _bite_direction: Vector3
var _previous_target_position: Vector3
var _lunge_hit: bool = false
var _bite_resolved: bool = false


func _ready() -> void:
  _bite_impact_time = _get_bite_method_time(&'_bite')
  _lunge_start_time = _get_bite_method_time(&'_begin_lunge')
  _set_appearance()
  _head_base_y = head.position.y
  _head_bob_phase = randf() * TAU
  if preview:
    set_physics_process(false)
  else:
    _growl_timer = RandomTimer.new()
    _growl_timer.min_time = growl_min_time
    _growl_timer.max_time = growl_max_time
    add_child(_growl_timer)
    _growl_timer.timeout.connect(_on_growl_timer_timeout)


func _process(delta: float) -> void:
  if _biting:
    _head_bob_offset = 0.0
  elif preview or not velocity.is_zero_approx():
    var previous_phase := _head_bob_phase
    _head_bob_phase += delta * TAU / head_bob_period
    if not preview and floorf((_head_bob_phase + PI * 0.5) / PI) > floorf((previous_phase + PI * 0.5) / PI):
      footstep_audio.play()
    _head_bob_offset = sin(_head_bob_phase) * head_bob_height
  else:
    _head_bob_offset = move_toward(_head_bob_offset, 0.0, delta * head_bob_height)
  head.position.y = _head_base_y + _head_bob_offset


func _set_appearance() -> void:
  head_sprite.texture = _pick_texture(head_textures, head_variant)
  body.texture = _pick_texture(body_textures, body_variant)
  (body.material_override as StandardMaterial3D).albedo_texture = body.texture
  (head_sprite.material_override as StandardMaterial3D).albedo_texture = head_sprite.texture
  eyes.texture = _pick_texture(eye_textures, eye_variant)
  appearance.scale *= randf_range(1.0 - size_variation, 1.0 + size_variation)
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


func _physics_process(delta: float) -> void:
  velocity = Vector3.ZERO
  if target.is_dead:
    if _lunging:
      _resolve_lunge()
    return
  if _lunging:
    _update_lunge(delta)
    return
  if _biting:
    _previous_target_position = target.global_position
    return
  if not _engaged:
    if global_position.distance_squared_to(target.global_position) > engagement_distance * engagement_distance:
      return
    _engaged = true
    _growl_timer.start()
  if _within_bite_range():
    bite()
  else:
    velocity = global_position.direction_to(target.global_position) * speed
    move_and_slide()


func is_chasing() -> bool:
  return _engaged and not _dead and not preview and not target.is_dead


func take_shot() -> void:
  if _dead:
    return
  _dead = true
  _finish_bite()
  velocity = Vector3.ZERO
  set_physics_process(false)
  set_process(false)
  if _growl_timer:
    _growl_timer.stop()
  animation.stop()
  footstep_audio.stop()
  eyes.hide()
  mouth.hide()
  head_lift.position = Vector3.ZERO
  vocal_audio.stream = death_stream
  vocal_audio.bus = &'World SFX Heavy Reverb'
  vocal_audio.volume_db += 3.0
  vocal_audio.play()
  var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  for sprite: Sprite3D in [body, head_sprite]:
    var material := sprite.material_override as StandardMaterial3D
    material.emission_energy_multiplier = 1.0
    tween.tween_property(material, 'emission_energy_multiplier', 0.0, hit_flash_duration)
  tween.tween_property(head, 'position:y', _head_base_y - head_collapse_distance, 0.25)


func _within_bite_range() -> bool:
  return global_position.distance_squared_to(target.global_position) <= bite_range * bite_range


func get_bite_windup_progress() -> float:
  if not _biting:
    return 0.0
  if _lunging or _bite_resolved:
    return 1.0
  return clampf(animation.current_animation_position / maxf(_lunge_start_time, 0.001), 0.0, 1.0)


func get_bite_focus_position() -> Vector3:
  return mouth.global_position


func _get_bite_method_time(method: StringName) -> float:
  var clip: Animation = animation.get_animation(&'bite')
  for track: int in range(clip.get_track_count()):
    if clip.track_get_type(track) != Animation.TYPE_METHOD:
      continue
    for key: int in range(clip.track_get_key_count(track)):
      if clip.method_track_get_name(track, key) == method:
        return clip.track_get_key_time(track, key)
  return clip.length


func bite() -> void:
  if _dead or _biting or is_queued_for_deletion() or (not preview and target.is_dead):
    return
  _biting = true
  _bite_resolved = false
  _lunge_hit = false
  if not preview:
    _bite_direction = target.global_position - global_position
    _bite_direction.y = 0.0
    _bite_direction = _bite_direction.normalized() if not _bite_direction.is_zero_approx() else Vector3.RIGHT
    _previous_target_position = target.global_position
  vocal_audio.stream = growl_stream
  vocal_audio.play()
  animation.play('bite', -1.0, _lunge_start_time / bite_windup)
  bite_started.emit(self)


func _begin_lunge() -> void:
  if _dead or not _biting or _lunging or _bite_resolved:
    return
  if preview:
    animation.play('bite', -1.0, 1.0)
    return
  _lunging = true
  _lunge_remaining = lunge_distance
  animation.pause()
  animation.seek(_lunge_start_time, true, true)


func _update_lunge(delta: float) -> void:
  var start := global_position
  var motion := _bite_direction * minf(lunge_speed * delta, _lunge_remaining)
  var collision := move_and_collide(motion)
  var traveled := global_position - start
  velocity = traveled / maxf(delta, 0.001)
  _lunge_remaining -= traveled.length()
  # sweep relative movement so neither fast lunges nor a crossing player skip the hit.
  var relative_start := Vector2(start.x - _previous_target_position.x, start.z - _previous_target_position.z)
  var relative_end := Vector2(global_position.x - target.global_position.x, global_position.z - target.global_position.z)
  var nearest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, relative_start, relative_end)
  _lunge_hit = nearest.length_squared() <= bite_hit_radius * bite_hit_radius
  _previous_target_position = target.global_position
  if _lunge_hit or collision != null or _lunge_remaining <= 0.001:
    _resolve_lunge()


func _resolve_lunge() -> void:
  _lunging = false
  velocity = Vector3.ZERO
  _bite()
  animation.play('bite', -1.0, 1.0)
  animation.seek(_bite_impact_time, true, true)


func _bite() -> void:
  if _dead or _lunging or _bite_resolved or is_queued_for_deletion():
    return
  _bite_resolved = true
  vocal_audio.stream = bite_stream
  vocal_audio.play()
  if not preview and not target.is_dead and _lunge_hit:
    target.take_bite()
    bite_landed.emit(self)


func _finish_bite() -> void:
  if not _biting:
    return
  _biting = false
  _lunging = false
  bite_finished.emit(self)


func _on_animation_finished(animation_name: StringName) -> void:
  if animation_name == &'bite':
    _finish_bite()


func _on_growl_timer_timeout() -> void:
  if _dead or not _engaged or _biting or target.is_dead or vocal_audio.playing:
    return
  vocal_audio.stream = growl_stream
  vocal_audio.play()
