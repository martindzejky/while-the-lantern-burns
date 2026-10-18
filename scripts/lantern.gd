class_name Lantern
extends Node3D

signal carried_changed(carried: bool)
signal lever_changed(openness: float)

@export var grip: Marker3D
@export var light: OmniLight3D
@export var visuals: CameraFacing
@export var max_energy: float = 100.0
@export var energy_drain: float = 5.0
@export var energy_per_press: float = 15.0
@export_range(0.01, 1.0, 0.01) var full_light_threshold: float = 0.7
@export_range(0.05, 5.0, 0.05) var lever_return_time: float = 0.8
@export var min_radius: float = 0.7
@export var max_radius: float = 8.0
@export var min_brightness: float = 0.15
@export var max_brightness: float = 1.1
@export var flicker_noise: Noise
@export_range(0.0, 0.2, 0.005) var flicker_amount: float = 0.04

var energy: float = 0.0
var is_carried: bool = false
var lever_openness: float = 1.0

var _flicker_time: float = 0.0


func _ready() -> void:
  energy = max_energy
  _update_light()


func _process(delta: float) -> void:
  _flicker_time += delta
  energy = maxf(energy - energy_drain * delta, 0.0)
  if lever_openness < 1.0:
    lever_openness = move_toward(lever_openness, 1.0, delta / lever_return_time)
    lever_changed.emit(lever_openness)
  _update_light()


func _update_light() -> void:
  var charge := clampf(energy / (max_energy * full_light_threshold), 0.0, 1.0)
  var noise := clampf(flicker_noise.get_noise_1d(_flicker_time) * 0.5 + 0.5, 0.0, 1.0)
  charge *= 1.0 - noise * flicker_amount
  light.omni_range = lerpf(min_radius, max_radius, charge)
  light.light_energy = lerpf(min_brightness, max_brightness, charge)


func set_carried(carried: bool) -> void:
  is_carried = carried
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
