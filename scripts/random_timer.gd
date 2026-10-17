class_name RandomTimer
extends Timer

@export var min_time: float = 1.0
@export var max_time: float = 2.0


func _ready() -> void:
  wait_time = randf_range(min_time, max_time)
  timeout.connect(_on_timeout)


func _on_timeout() -> void:
  wait_time = randf_range(min_time, max_time)
