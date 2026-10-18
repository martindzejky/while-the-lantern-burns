@tool
extends Node3D

@export var distance_blur: MeshInstance3D
@export var overlay: ColorRect

@export_group('Color')
@export_range(0.0, 2.0, 0.01) var brightness: float = 1.0:
  set(value):
    brightness = value
    _update_effects()
@export_range(0.0, 2.0, 0.01) var contrast: float = 1.0:
  set(value):
    contrast = value
    _update_effects()
@export_range(0.0, 2.0, 0.01) var saturation: float = 1.0:
  set(value):
    saturation = value
    _update_effects()
@export var tint: Color = Color.WHITE:
  set(value):
    tint = value
    _update_effects()

@export_group('Vignette')
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.22:
  set(value):
    vignette_strength = value
    _update_effects()
@export_range(0.0, 1.5, 0.01) var vignette_start: float = 0.45:
  set(value):
    vignette_start = value
    _update_effects()
@export_range(0.0, 2.0, 0.01) var vignette_end: float = 1.25:
  set(value):
    vignette_end = value
    _update_effects()

@export_group('Distant Blur')
@export var blur_enabled: bool = true:
  set(value):
    blur_enabled = value
    _update_effects()
@export_range(0.0, 100.0, 0.1) var far_blur_start: float = 18.0:
  set(value):
    far_blur_start = value
    _update_effects()
@export_range(0.0, 100.0, 0.1) var far_blur_end: float = 26.0:
  set(value):
    far_blur_end = value
    _update_effects()
@export_range(0.0, 32.0, 0.1, 'or_greater') var blur_radius_pixels: float = 1.5:
  set(value):
    blur_radius_pixels = value
    _update_effects()


func _ready() -> void:
  _update_effects()


func _update_effects() -> void:
  if not is_node_ready():
    return
  var color_material := overlay.material as ShaderMaterial
  color_material.set_shader_parameter('brightness', brightness)
  color_material.set_shader_parameter('contrast', contrast)
  color_material.set_shader_parameter('saturation', saturation)
  color_material.set_shader_parameter('tint', tint)
  color_material.set_shader_parameter('vignette_strength', vignette_strength)
  color_material.set_shader_parameter('vignette_start', vignette_start)
  color_material.set_shader_parameter('vignette_end', vignette_end)
  distance_blur.visible = blur_enabled
  var blur_material := distance_blur.material_override as ShaderMaterial
  blur_material.set_shader_parameter('far_blur_start', far_blur_start)
  blur_material.set_shader_parameter('far_blur_end', far_blur_end)
  blur_material.set_shader_parameter('blur_radius_pixels', blur_radius_pixels)
