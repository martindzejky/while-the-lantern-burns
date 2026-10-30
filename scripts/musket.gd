class_name Musket
extends Node3D

signal equipped
signal unequipped
signal aiming_changed(aiming: bool)
signal fired(hit: Dictionary)
signal reload_changed
signal lit_changed(lit: bool)
signal fuse_expired
signal trigger_pulled
signal trigger_ready

enum ReloadState { EMPTY, BALL_INSERTED, LOADED }

@export var rear_grip: Marker3D
@export var front_grip: Marker3D
@export var sprite: Sprite3D
@export var visuals: CameraFacing
@export var muzzle: Marker3D
@export var sparks: CPUParticles3D
@export var spark_light: OmniLight3D
@export var spark_flicker_noise: Noise
@export_range(0.0, 3.0, 0.05) var spark_light_min_energy: float = 0.05
@export_range(0.0, 3.0, 0.05) var spark_light_max_energy: float = 0.35
@export var flash_scene: PackedScene
@export var smoke_scene: PackedScene
@export var pickup_audio: AudioStreamPlayer3D
@export var ball_audio: AudioStreamPlayer
@export var loaded_audio: AudioStreamPlayer
@export var aim_audio: AudioStreamPlayer3D
@export var ignite_audio: AudioStreamPlayer3D
@export var burning_audio: AudioStreamPlayer3D
@export var shot_audio: AudioStreamPlayer3D
@export var click_audio: AudioStreamPlayer3D
@export var ramrod_audio: AudioStreamPlayer
@export var ramrod_volume_db: float = -14.0
@export_range(0.05, 2.0, 0.05) var trigger_delay: float = 0.5
@export var shot_range: float = 30.0
@export var ray_height: float = 0.1
@export_range(0.1, 30.0, 0.1) var fuse_duration: float = 10.0

var is_owned: bool = false
var is_aiming: bool = false
var reload_state: ReloadState = ReloadState.EMPTY
var ramrod_insertion: float = 0.0
var is_lit: bool = false
var is_trigger_pending: bool = false
var _fuse_timer: Timer = Timer.new()
var _trigger_timer: Timer = Timer.new()
var _ramrod_motion: float = 0.0
var _ground_visuals_transform: Transform3D
var _spark_flicker_time: float = 0.0


func _ready() -> void:
  _ground_visuals_transform = visuals.transform
  _fuse_timer.one_shot = true
  _fuse_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
  _fuse_timer.timeout.connect(_on_fuse_timer_timeout)
  add_child(_fuse_timer)
  _trigger_timer.one_shot = true
  _trigger_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
  _trigger_timer.timeout.connect(_on_trigger_timer_timeout)
  add_child(_trigger_timer)
  ramrod_audio.volume_db = -80.0
  spark_light.visible = false


func _process(delta: float) -> void:
  _ramrod_motion = move_toward(_ramrod_motion, 0.0, delta * 6.0)
  ramrod_audio.volume_db = ramrod_volume_db + linear_to_db(maxf(_ramrod_motion, 0.0001))
  if is_lit:
    _spark_flicker_time += delta
    var flicker := clampf(spark_flicker_noise.get_noise_1d(_spark_flicker_time) * 0.5 + 0.5, 0.0, 1.0)
    spark_light.light_energy = lerpf(spark_light_min_energy, spark_light_max_energy, flicker)


func warm_up_effects() -> void:
  var spark_range: float = spark_light.omni_range
  # reach visible materials while the loading cover hides the warm-up.
  spark_light.omni_range = 64.0
  spark_light.light_energy = spark_light_max_energy
  spark_light.visible = true
  sparks.emitting = true
  # compile the fuse-light combination before adding the shot's extra light.
  for frame: int in range(2):
    await RenderingServer.frame_post_draw
    if not is_instance_valid(self):
      return
  spark_light.omni_range = spark_range
  var flash := flash_scene.instantiate() as MuzzleFlash
  add_child(flash)
  var smoke := smoke_scene.instantiate() as CPUParticles3D
  add_child(smoke)
  for frame: int in range(2):
    await RenderingServer.frame_post_draw
    if not is_instance_valid(self):
      return
  if is_instance_valid(flash):
    flash.queue_free()
  if is_instance_valid(smoke):
    smoke.queue_free()
  sparks.emitting = false
  spark_light.visible = false


func ignite() -> void:
  if not is_owned or reload_state != ReloadState.LOADED or is_lit:
    return
  is_lit = true
  spark_light.light_energy = spark_light_max_energy
  spark_light.visible = true
  sparks.restart()
  sparks.emitting = true
  _fuse_timer.start(fuse_duration)
  ignite_audio.play()
  burning_audio.play()
  lit_changed.emit(true)


func insert_ball() -> void:
  if not is_owned or is_aiming or reload_state != ReloadState.EMPTY:
    return
  reload_state = ReloadState.BALL_INSERTED
  ball_audio.play()
  reload_changed.emit()


func can_use_ramrod() -> bool:
  return is_owned and not is_aiming and not is_lit and reload_state != ReloadState.EMPTY


func move_ramrod(amount: float) -> void:
  if not can_use_ramrod():
    return
  var previous_insertion := ramrod_insertion
  ramrod_insertion = clampf(ramrod_insertion + amount, 0.0, 1.0)
  var speed := absf(ramrod_insertion - previous_insertion) / maxf(get_process_delta_time(), 0.001)
  _ramrod_motion = maxf(_ramrod_motion, clampf(speed / 4.0, 0.0, 1.0))
  if ramrod_insertion == 1.0 and reload_state != ReloadState.LOADED:
    reload_state = ReloadState.LOADED
    loaded_audio.play()
  reload_changed.emit()


func cancel_ramrod() -> void:
  set_ramrod_dragging(false)
  if reload_state == ReloadState.EMPTY:
    return
  ramrod_insertion = 0.0
  if reload_state != ReloadState.LOADED:
    reload_state = ReloadState.BALL_INSERTED
  reload_changed.emit()


func set_ramrod_dragging(dragging: bool) -> void:
  if dragging:
    if not ramrod_audio.playing:
      ramrod_audio.play()
    ramrod_audio.stream_paused = false
  else:
    _ramrod_motion = 0.0
    ramrod_audio.volume_db = -80.0
    ramrod_audio.stream_paused = true


func equip() -> void:
  is_owned = true
  visuals.set_process(false)
  visuals.transform = Transform3D.IDENTITY
  sprite.rotation.z = 1.0
  pickup_audio.play()
  equipped.emit()


func drop() -> void:
  is_owned = false
  set_aiming(false)
  sprite.rotation.z = 0.0
  visuals.transform = _ground_visuals_transform
  visuals.set_process(true)
  set_ramrod_dragging(false)
  pickup_audio.play()
  unequipped.emit()


func set_aiming(aiming: bool) -> void:
  if is_aiming == aiming:
    return
  is_aiming = aiming
  aim_audio.play()
  if not aiming:
    sprite.rotation.z = 1.0
  aiming_changed.emit(aiming)


func set_held_angle(angle: float) -> void:
  sprite.rotation.z = angle


func aim(direction: Vector2) -> void:
  var mirror := -1.0 if sprite.global_basis.determinant() < 0.0 else 1.0
  sprite.rotation.z = Vector2(direction.x * mirror, -direction.y).angle()


func pull_trigger() -> bool:
  if not is_owned or not is_aiming or is_trigger_pending:
    return false
  click_audio.play()
  if reload_state != ReloadState.LOADED or not is_lit:
    return false
  is_trigger_pending = true
  trigger_pulled.emit()
  _trigger_timer.start(trigger_delay)
  return true


func _on_trigger_timer_timeout() -> void:
  if is_trigger_pending and is_lit:
    trigger_ready.emit()


func fire(origin: Vector3, target: Vector3, excluded_body: RID) -> Dictionary:
  if not is_aiming or reload_state != ReloadState.LOADED or not is_lit:
    return {}
  var direction := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
  if direction.is_zero_approx():
    return {}

  var start := origin + Vector3.UP * ray_height
  var end := start + direction.normalized() * shot_range
  var query := PhysicsRayQueryParameters3D.create(start, end, 3, [excluded_body])
  query.collide_with_areas = true
  query.hit_from_inside = true
  var hit := get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():
    end = hit.position

  _discharge(end, hit)
  return hit


func _on_fuse_timer_timeout() -> void:
  if is_lit:
    fuse_expired.emit()


func fire_upwards() -> void:
  if reload_state != ReloadState.LOADED or not is_lit:
    return
  var direction := sprite.global_basis.x.normalized()
  _discharge(muzzle.global_position + direction * shot_range, {})


func _discharge(end: Vector3, hit: Dictionary) -> void:
  var flash := flash_scene.instantiate() as MuzzleFlash
  get_tree().current_scene.add_child(flash)
  flash.play(muzzle.global_position, end)
  var smoke := smoke_scene.instantiate() as CPUParticles3D
  smoke.top_level = true
  smoke.position = muzzle.global_position
  smoke.position.y = 0.0
  get_tree().current_scene.add_child(smoke)
  _fuse_timer.stop()
  _trigger_timer.stop()
  is_trigger_pending = false
  burning_audio.stop()
  shot_audio.play()
  sparks.emitting = false
  spark_light.visible = false
  reload_state = ReloadState.EMPTY
  is_lit = false
  reload_changed.emit()
  lit_changed.emit(false)
  print('Musket fired: ', hit.get('collider', 'miss'))
  fired.emit(hit)


func get_checkpoint() -> Dictionary:
  return {
    'owned': is_owned,
    'reload_state': reload_state,
    'ramrod_insertion': ramrod_insertion,
    'fuse_remaining': _fuse_timer.time_left if is_lit else 0.0,
  }


func restore_checkpoint(data: Dictionary) -> void:
  _trigger_timer.stop()
  is_trigger_pending = false
  _fuse_timer.stop()
  if data['owned']:
    equip()
  else:
    drop()
  pickup_audio.stop()
  reload_state = int(data['reload_state']) as ReloadState
  ramrod_insertion = float(data['ramrod_insertion'])
  var remaining := float(data['fuse_remaining'])
  is_lit = remaining > 0.0
  sparks.emitting = is_lit
  spark_light.visible = is_lit
  if is_lit:
    spark_light.light_energy = spark_light_max_energy
    sparks.restart()
    _fuse_timer.start(remaining)
    burning_audio.play()
  else:
    burning_audio.stop()
  reload_changed.emit()
  lit_changed.emit(is_lit)
