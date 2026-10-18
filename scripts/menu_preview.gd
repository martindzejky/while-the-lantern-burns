class_name MainMenu
extends Node3D

signal start_requested

@export var start_button: Button
@export var quit_button: Button
@export var title: Label
@export var buttons: VBoxContainer
@export var settings: AudioSettings
@export var settings_button: Button
@export var controls: ControlsScreen
@export var controls_button: Button


func _ready() -> void:
  quit_button.visible = not OS.has_feature('web')
  get_viewport().size_changed.connect(_update_type_size)
  _update_type_size()
  start_button.grab_focus()


func _update_type_size() -> void:
  var width := get_viewport().get_visible_rect().size.x
  title.add_theme_font_size_override('font_size', clampi(roundi(width * 0.043), 30, 64))


func _on_start_pressed() -> void:
  start_requested.emit()


func _on_settings_pressed() -> void:
  buttons.hide()
  title.hide()
  settings.open()


func _on_settings_closed() -> void:
  title.show()
  buttons.show()
  settings_button.grab_focus()


func _on_quit_pressed() -> void:
  get_tree().quit()


func _on_controls_pressed() -> void:
  buttons.hide()
  title.hide()
  controls.open()


func _on_controls_closed() -> void:
  title.show()
  buttons.show()
  controls_button.grab_focus()
