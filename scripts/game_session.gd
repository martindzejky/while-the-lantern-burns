class_name GameSession
extends Node3D

signal pause_requested
signal prepared

@export var player: Player
@export var musket: Musket
@export var hud: CanvasLayer
@export var loading: CanvasLayer
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
  player.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
  hud.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _unhandled_input(event: InputEvent) -> void:
  if _active and event.is_action_pressed('ui_cancel'):
    pause_requested.emit()
    get_viewport().set_input_as_handled()
