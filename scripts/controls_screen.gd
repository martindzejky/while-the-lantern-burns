class_name ControlsScreen
extends VBoxContainer

signal closed

@export var back_button: Button
@export var audio: UIAudio


func open() -> void:
  show()
  back_button.grab_focus()


func _on_back_pressed() -> void:
  hide()
  closed.emit()


func _unhandled_input(event: InputEvent) -> void:
  if is_visible_in_tree() and event.is_action_pressed('ui_cancel'):
    audio.play_click()
    _on_back_pressed()
    get_viewport().set_input_as_handled()
