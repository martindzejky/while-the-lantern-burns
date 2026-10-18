class_name GameSession
extends Node3D

signal pause_requested
signal retry_requested
signal menu_requested
signal prepared

@export var player: Player
@export var musket: Musket
@export var hud: CanvasLayer
@export var loading: CanvasLayer
@export var victory: VictoryScreen
@export var start_inactive: bool = false

var _active: bool = false
var is_prepared: bool = false


func _ready() -> void:
  set_active(false)
  var stored_transform: Transform3D = musket.global_transform
  musket.global_position = player.global_position
  await musket.warm_up_effects()
  musket.global_transform = stored_transform
  loading.queue_free()
  is_prepared = true
  set_active(not start_inactive)
  prepared.emit()


func set_active(active: bool) -> void:
  _active = active
  player.set_darkness_enabled(active)
  player.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
  hud.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _on_player_died() -> void:
  _active = false


func _on_retry_requested() -> void:
  retry_requested.emit()


func _on_menu_requested() -> void:
  menu_requested.emit()


func _on_exit_body_entered(body: Node3D) -> void:
  if body != player or not _active or player.is_dead:
    return
  set_active(false)
  hud.hide()
  process_mode = Node.PROCESS_MODE_DISABLED
  victory.open()


func _unhandled_input(event: InputEvent) -> void:
  if _active and event.is_action_pressed('ui_cancel'):
    pause_requested.emit()
    get_viewport().set_input_as_handled()
