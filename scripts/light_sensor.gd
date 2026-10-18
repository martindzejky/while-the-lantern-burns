class_name LightSensor
extends Node3D

# one sensor per scene; exclude visual layer 2 from the main camera
# the sensor camera includes world geometry so it still casts real shadows

signal exposure_changed(exposure: float)
signal light_changed(lit: bool)

@export var probe: Sprite3D
@export var camera: Camera3D
@export var viewport: SubViewport
@export var threshold: float = 0.02
@export var sample_interval: float = 0.1

var exposure: float = 0.0
var is_lit: bool = false
var _timer: Timer = Timer.new()
var _sampling: bool = false


func _ready() -> void:
  viewport.world_3d = get_world_3d()
  _timer.wait_time = sample_interval
  _timer.timeout.connect(_sample)
  add_child(_timer)
  _timer.start()


func get_preview_texture() -> Texture2D:
  return viewport.get_texture()


func _sample() -> void:
  if _sampling:
    return
  _sampling = true
  var main_camera := get_viewport().get_camera_3d()
  # match the view direction so billboard shadow casters face the same way
  camera.global_transform = Transform3D(
    main_camera.global_basis, probe.global_position + main_camera.global_basis.z * 5.0
  )
  viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
  await RenderingServer.frame_post_draw
  if not is_instance_valid(self):
    return
  var image := viewport.get_texture().get_image()
  var center: Vector2i = image.get_size() / 2
  exposure = image.get_pixelv(center).srgb_to_linear().get_luminance()
  var lit := exposure >= threshold
  if lit != is_lit:
    is_lit = lit
    light_changed.emit(is_lit)
  exposure_changed.emit(exposure)
  _sampling = false
