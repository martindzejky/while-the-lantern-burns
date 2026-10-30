class_name CaveGameplay
extends Node3D

signal pause_requested
signal retry_requested
signal menu_requested
signal level_completed
signal escaped
signal prepared

@export var player: Player
@export var lantern: Lantern
@export var musket: Musket
@export var prompts: GameplayPrompts
@export var camera_controller: CameraController
@export var cave_container: Node3D
@export var level_scenes: Array[PackedScene]
@export var equipment_hud: CanvasLayer
@export var loading_overlay: CanvasLayer
@export var victory_screen: VictoryScreen
@export var start_inactive: bool = false

var initial_checkpoint: Dictionary = {}
var level_id: int = 0
var is_prepared: bool = false
var _active: bool = false
var _level: CaveLevel


func _ready() -> void:
  set_active(false)
  _prepare.call_deferred()


func _prepare() -> void:
  level_id = int(initial_checkpoint.get('level_id', 0))
  _level = level_scenes[level_id].instantiate() as CaveLevel
  for enemy: Enemy in _level.enemies:
    enemy.target = player
    enemy.bite_started.connect(camera_controller._on_bite_started)
    enemy.bite_finished.connect(camera_controller._on_bite_finished)
    enemy.bite_landed.connect(camera_controller._on_bite_landed)
  for focus: CameraFocus in _level.focuses:
    focus.focus_entered.connect(camera_controller._on_focus_entered)
    focus.focus_exited.connect(camera_controller._on_focus_exited)
  _level.exit.body_entered.connect(_on_exit_body_entered)
  cave_container.add_child(_level)

  var player_state: Dictionary = initial_checkpoint.get('player', player.get_checkpoint())
  if _level.lantern_focus != null:
    if player_state['lantern']['discovered']:
      _level.lantern_focus.queue_free()
    else:
      lantern.carried_changed.connect(_level.lantern_focus._on_lantern_carried_changed)
  if _level.musket_focus != null:
    if player_state['musket']['owned']:
      _level.musket_focus.queue_free()
    else:
      musket.equipped.connect(_level.musket_focus.queue_free)
  var lantern_position: Vector3 = _level.lantern_spawn.global_position
  if player_state['lantern']['discovered']:
    lantern_position = _level.entry.global_position + Vector3(1.0, 0.0, 0.0)
  player.restore_checkpoint(
    player_state, _level.entry.global_position, lantern_position, _level.musket_spawn.global_position
  )
  camera_controller.set_level(_level.camera_bounds, _level.enemies)

  var stored_transform: Transform3D = musket.global_transform
  musket.global_position = player.global_position
  await musket.warm_up_effects()
  musket.global_transform = stored_transform
  musket.restore_checkpoint(player_state['musket'])
  if initial_checkpoint.has('prompts'):
    prompts.restore_checkpoint(initial_checkpoint['prompts'])
  loading_overlay.queue_free()
  is_prepared = true
  set_active(not start_inactive)
  prepared.emit()


func get_checkpoint() -> Dictionary:
  return {'level_id': level_id, 'player': player.get_checkpoint(), 'prompts': prompts.get_checkpoint()}


func set_active(active: bool) -> void:
  _active = active
  player.set_darkness_enabled(active)
  process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _on_player_died() -> void:
  _active = false


func _on_retry_requested() -> void:
  retry_requested.emit()


func _on_menu_requested() -> void:
  menu_requested.emit()


func _on_exit_body_entered(body: Node3D) -> void:
  if body != player or not _active or player.is_dead:
    return
  _active = false
  _finish_level.call_deferred()


func _finish_level() -> void:
  set_active(false)
  if level_id < level_scenes.size() - 1:
    level_completed.emit()
  else:
    equipment_hud.hide()
    victory_screen.open()
    escaped.emit()


func _unhandled_input(event: InputEvent) -> void:
  if _active and event.is_action_pressed('ui_cancel'):
    pause_requested.emit()
    get_viewport().set_input_as_handled()
