extends Node

@export var rumble: AudioStreamPlayer
@export var growl: AudioStreamPlayer
@export var bite: AudioStreamPlayer
@export var fade_duration: float = 0.12

var _warning: bool = false
var _dead: bool = false
var _rumble_volume: float
var _growl_volume: float
var _fade: Tween


func _ready() -> void:
  _rumble_volume = rumble.volume_db
  _growl_volume = growl.volume_db


func _on_darkness_progress_changed(progress: float) -> void:
  if _dead:
    return
  if progress > 0.0 and not _warning:
    _warning = true
    if _fade:
      _fade.kill()
    rumble.volume_db = _rumble_volume
    growl.volume_db = -60.0
    rumble.play()
    growl.play()
  elif is_zero_approx(progress) and _warning:
    _stop_warning(false)
  if _warning:
    growl.volume_linear = db_to_linear(_growl_volume) * smoothstep(0.0, 1.0, progress)


func _stop_warning(immediate: bool) -> void:
  _warning = false
  if _fade:
    _fade.kill()
  if immediate:
    rumble.stop()
    growl.stop()
    return
  _fade = create_tween().set_parallel(true)
  _fade.tween_property(rumble, 'volume_db', -60.0, fade_duration)
  _fade.tween_property(growl, 'volume_db', -60.0, fade_duration)
  _fade.chain().tween_callback(rumble.stop)
  _fade.tween_callback(growl.stop)


func _on_darkness_killed() -> void:
  _stop_warning(true)
  bite.play()


func _on_player_died() -> void:
  _dead = true
  _stop_warning(true)
