extends Node3D

@export_file('*.tscn') var game_scene: String
@export var start_button: Button
@export var quit_button: Button
@export var title: Label


func _ready() -> void:
  quit_button.visible = not OS.has_feature('web')
  get_viewport().size_changed.connect(_update_type_size)
  _update_type_size()
  start_button.grab_focus()


func _update_type_size() -> void:
  var width := get_viewport().get_visible_rect().size.x
  title.add_theme_font_size_override('font_size', clampi(roundi(width * 0.043), 30, 64))


func _on_start_pressed() -> void:
  var error := get_tree().change_scene_to_file(game_scene)
  if error != OK:
    push_error('Could not open game scene: %s' % error_string(error))


func _on_quit_pressed() -> void:
  get_tree().quit()
