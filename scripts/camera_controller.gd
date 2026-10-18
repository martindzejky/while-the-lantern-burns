class_name CameraController
extends Node3D

@export var target: Player
@export var camera: Camera3D
@export_range(1.0, 120.0, 0.5) var follow_fov: float = 43.0
@export_range(0.1, 20.0, 0.1) var follow_response: float = 6.0
@export_group('Bite emphasis')
@export var bite_zoom_enabled: bool = true
@export_range(1.0, 120.0, 0.5) var bite_fov: float = 32.0
@export_range(0.0, 1.0, 0.05) var bite_focus_weight: float = 0.3
@export_range(0.1, 20.0, 0.1) var bite_response: float = 3.0

var _focus_points: Array[CameraFocus] = []
var _biting_enemies: Array[Enemy] = []
var _zoom_enemy: Enemy
var _bite_start_fov: float
var _death_closeup: bool = false
var _death_focus: Vector3


func _ready() -> void:
  global_position = target.global_position
  camera.fov = follow_fov
  camera.make_current()


func _process(delta: float) -> void:
  if _death_closeup:
    camera.fov = lerpf(camera.fov, bite_fov, 1.0 - exp(-bite_response * delta))
    global_position = global_position.lerp(_death_focus, 1.0 - exp(-follow_response * delta))
    return
  var desired_position: Vector3 = target.global_position
  var strongest_weight: float = 0.0
  for index: int in range(_focus_points.size() - 1, -1, -1):
    var focus: CameraFocus = _focus_points[index]
    if not is_instance_valid(focus):
      _focus_points.remove_at(index)
      continue
    var weight: float = focus.get_weight(target.global_position)
    if weight > strongest_weight:
      strongest_weight = weight
      desired_position = target.global_position.lerp(focus.global_position, weight)

  var biting_enemy: Enemy = _get_nearest_biting_enemy()
  var blend: float = 1.0 - exp(-follow_response * delta)
  if bite_zoom_enabled and biting_enemy != null:
    if _zoom_enemy != biting_enemy:
      _zoom_enemy = biting_enemy
      _bite_start_fov = camera.fov
    var progress: float = smoothstep(0.0, 1.0, biting_enemy.get_bite_windup_progress())
    var mouth_position: Vector3 = biting_enemy.get_bite_focus_position()
    var bite_position: Vector3 = target.global_position.lerp(mouth_position, bite_focus_weight)
    bite_position.y = mouth_position.y
    desired_position = desired_position.lerp(bite_position, progress)
    blend = 1.0 - exp(-bite_response * delta)
    var desired_fov: float = lerpf(_bite_start_fov, bite_fov, progress)
    camera.fov = lerpf(camera.fov, desired_fov, blend)
  else:
    _zoom_enemy = null
    camera.fov = lerpf(camera.fov, follow_fov, blend)

  global_position = global_position.lerp(desired_position, blend)


func _get_nearest_biting_enemy() -> Enemy:
  var nearest: Enemy = null
  var nearest_distance: float = INF
  for index: int in range(_biting_enemies.size() - 1, -1, -1):
    var enemy: Enemy = _biting_enemies[index]
    if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
      _biting_enemies.remove_at(index)
      continue
    var distance: float = target.global_position.distance_squared_to(enemy.global_position)
    if distance < nearest_distance:
      nearest_distance = distance
      nearest = enemy
  return nearest


func _on_focus_entered(focus: CameraFocus, body: Node3D) -> void:
  if body == target and not _focus_points.has(focus):
    _focus_points.append(focus)


func _on_focus_exited(focus: CameraFocus, body: Node3D) -> void:
  if body == target:
    _focus_points.erase(focus)


func _on_bite_started(enemy: Enemy) -> void:
  if enemy.target == target and not _biting_enemies.has(enemy):
    _biting_enemies.append(enemy)


func _on_bite_finished(enemy: Enemy) -> void:
  _biting_enemies.erase(enemy)


func _on_bite_landed(enemy: Enemy) -> void:
  if not bite_zoom_enabled or enemy.target != target or not target.is_dead:
    return
  var mouth_position: Vector3 = enemy.get_bite_focus_position()
  _death_focus = target.global_position.lerp(mouth_position, bite_focus_weight)
  _death_focus.y = mouth_position.y
  _death_closeup = true
