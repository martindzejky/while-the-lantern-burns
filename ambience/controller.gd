extends Node

@export var target: Node3D
@export var one_shots: AudioStreamPlayer3D
@export var min_time: float = 2.0
@export var max_time: float = 6.0
@export var min_distance: float = 3.0
@export var max_distance: float = 8.0


func _ready() -> void:
  var timer := RandomTimer.new()
  timer.min_time = min_time
  timer.max_time = max_time
  add_child(timer)
  timer.timeout.connect(_on_one_shot_timer_timeout)
  timer.start()


func _on_one_shot_timer_timeout() -> void:
  if one_shots.playing:
    return
  var angle := randf_range(0.0, TAU)
  var distance := randf_range(min_distance, max_distance)
  one_shots.global_position = target.global_position + Vector3(cos(angle) * distance, 0.2, sin(angle) * distance)
  one_shots.play()
