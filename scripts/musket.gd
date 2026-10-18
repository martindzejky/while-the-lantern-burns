class_name Musket
extends Node3D

signal equipped
signal unequipped
signal aiming_changed(aiming: bool)
signal fired(hit: Dictionary)
signal reload_changed
signal lit_changed(lit: bool)
signal fuse_expired

enum ReloadState { EMPTY, BALL_INSERTED, LOADED }

@export var rear_grip: Marker3D
@export var front_grip: Marker3D
@export var sprite: Sprite3D
@export var visuals: CameraFacing
@export var muzzle: Marker3D
@export var sparks: CPUParticles3D
@export var flash_scene: PackedScene
@export var smoke_scene: PackedScene
@export var shot_range: float = 30.0
@export var ray_height: float = 0.1
@export_range(0.1, 30.0, 0.1) var fuse_duration: float = 10.0

var is_owned: bool = false
var is_aiming: bool = false
var reload_state: ReloadState = ReloadState.EMPTY
var ramrod_insertion: float = 0.0
var is_lit: bool = false
var _fuse_timer: Timer = Timer.new()
var _ground_visuals_transform: Transform3D


func _ready() -> void:
  _ground_visuals_transform = visuals.transform
  _fuse_timer.one_shot = true
  _fuse_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
  _fuse_timer.timeout.connect(_on_fuse_timer_timeout)
  add_child(_fuse_timer)


func warm_up_effects() -> void:
  sparks.emitting = true
  var flash := flash_scene.instantiate() as MuzzleFlash
  add_child(flash)
  var smoke := smoke_scene.instantiate() as CPUParticles3D
  add_child(smoke)
  for frame: int in range(2):
    await RenderingServer.frame_post_draw
    if not is_instance_valid(self):
      return
  flash.queue_free()
  smoke.queue_free()
  sparks.emitting = false


func ignite() -> void:
  if not is_owned or reload_state != ReloadState.LOADED or is_lit:
    return
  is_lit = true
  sparks.restart()
  sparks.emitting = true
  _fuse_timer.start(fuse_duration)
  lit_changed.emit(true)


func insert_ball() -> void:
  if not is_owned or is_aiming or reload_state != ReloadState.EMPTY:
    return
  reload_state = ReloadState.BALL_INSERTED
  reload_changed.emit()


func can_use_ramrod() -> bool:
  return is_owned and not is_aiming and not is_lit and reload_state != ReloadState.EMPTY


func move_ramrod(amount: float) -> void:
  if not can_use_ramrod():
    return
  ramrod_insertion = clampf(ramrod_insertion + amount, 0.0, 1.0)
  if ramrod_insertion == 1.0:
    reload_state = ReloadState.LOADED
  reload_changed.emit()


func cancel_ramrod() -> void:
  if reload_state == ReloadState.EMPTY:
    return
  ramrod_insertion = 0.0
  if reload_state != ReloadState.LOADED:
    reload_state = ReloadState.BALL_INSERTED
  reload_changed.emit()


func equip() -> void:
  is_owned = true
  visuals.set_process(false)
  visuals.transform = Transform3D.IDENTITY
  sprite.rotation.z = 1.0
  equipped.emit()


func drop() -> void:
  is_owned = false
  set_aiming(false)
  sprite.rotation.z = 0.0
  visuals.transform = _ground_visuals_transform
  visuals.set_process(true)
  unequipped.emit()


func set_aiming(aiming: bool) -> void:
  if is_aiming == aiming:
    return
  is_aiming = aiming
  if not aiming:
    sprite.rotation.z = 1.0
  aiming_changed.emit(aiming)


func set_held_angle(angle: float) -> void:
  sprite.rotation.z = angle


func aim(direction: Vector2) -> void:
  var mirror := -1.0 if sprite.global_basis.determinant() < 0.0 else 1.0
  sprite.rotation.z = Vector2(direction.x * mirror, -direction.y).angle()


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
  sparks.emitting = false
  reload_state = ReloadState.EMPTY
  is_lit = false
  reload_changed.emit()
  lit_changed.emit(false)
  print('Musket fired: ', hit.get('collider', 'miss'))
  fired.emit(hit)
