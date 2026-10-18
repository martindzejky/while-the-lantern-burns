class_name Lantern
extends Node3D

signal carried_changed(carried: bool)
signal lever_changed(openness: float)

@export var grip: Marker3D
@export var light: OmniLight3D
@export var visuals: CameraFacing
@export var swing: Node3D
@export var swing_limit_degrees: float = 30.0
@export var swing_response: float = 0.65
@export var swing_stiffness: float = 45.0
@export var swing_damping: float = 5.0
@export var max_energy: float = 100.0
@export var energy_drain: float = 5.0
@export var energy_per_press: float = 15.0
@export_range(0.01, 1.0, 0.01) var full_light_threshold: float = 0.7
@export_range(0.05, 5.0, 0.05) var lever_return_time: float = 0.8
@export var min_radius: float = 0.7
@export var max_radius: float = 8.0
@export var min_brightness: float = 0.15
@export var max_brightness: float = 1.1
## x: charge (0 = empty, 1 = full light); y: blend from minimum to maximum radius.
@export var radius_curve: Curve
## x: charge (0 = empty, 1 = full light); y: blend from minimum to maximum brightness.
@export var brightness_curve: Curve
@export var flicker_noise: Noise
@export_range(0.0, 0.2, 0.005) var flicker_amount: float = 0.04

var energy: float = 0.0
var is_carried: bool = false
var lever_openness: float = 1.0

var _flicker_time: float = 0.0
var _swing_started: bool = false
var _previous_grip_position: Vector3
var _previous_velocity: float = 0.0
var _swing_velocity: float = 0.0


func _ready() -> void:
  energy = max_energy
  _update_light()


func _process(delta: float) -> void:
  _update_swing(delta)
  _flicker_time += delta
  energy = maxf(energy - energy_drain * delta, 0.0)
  if lever_openness < 1.0:
    lever_openness = move_toward(lever_openness, 1.0, delta / lever_return_time)
    lever_changed.emit(lever_openness)
  _update_light()


func _update_swing(delta: float) -> void:
  if not is_carried or delta <= 0.0:
    return
  var grip_position := grip.global_position
  if not _swing_started:
    _previous_grip_position = grip_position
    _swing_started = true
    return
  var velocity := (grip_position - _previous_grip_position).dot(
    visuals.global_basis.x.normalized()
  ) / delta
  _previous_grip_position = grip_position
  _swing_velocity -= (velocity - _previous_velocity) * swing_response
  _previous_velocity = velocity
  var step := minf(delta, 0.05)
  _swing_velocity += (-swing_stiffness * swing.rotation.z - swing_damping * _swing_velocity) * step
  var limit := deg_to_rad(swing_limit_degrees)
  swing.rotation.z = clampf(swing.rotation.z + _swing_velocity * step, -limit, limit)
  if absf(swing.rotation.z) >= limit and swing.rotation.z * _swing_velocity > 0.0:
    _swing_velocity = 0.0


func _update_light() -> void:
  var charge := clampf(energy / (max_energy * full_light_threshold), 0.0, 1.0)
  var noise := clampf(flicker_noise.get_noise_1d(_flicker_time) * 0.5 + 0.5, 0.0, 1.0)
  charge *= 1.0 - noise * flicker_amount
  light.omni_range = lerpf(
    min_radius, max_radius, clampf(radius_curve.sample_baked(charge), 0.0, 1.0)
  )
  light.light_energy = lerpf(
    min_brightness, max_brightness, clampf(brightness_curve.sample_baked(charge), 0.0, 1.0)
  )


func set_carried(carried: bool) -> void:
  is_carried = carried
  _swing_started = false
  _previous_velocity = 0.0
  _swing_velocity = 0.0
  swing.rotation.z = 0.0
  visuals.set_process(not carried)
  if carried:
    visuals.transform = Transform3D.IDENTITY
  carried_changed.emit(carried)


func charge() -> void:
  var stroke := lever_openness * lever_openness
  energy = minf(energy + energy_per_press * stroke, max_energy)
  lever_openness = 0.0
  lever_changed.emit(lever_openness)
  _update_light()
