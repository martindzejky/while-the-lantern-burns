class_name PauseMenu
extends Control

signal continue_requested
signal menu_requested

@export var continue_button: Button
@export var audio: UIAudio


func open() -> void:
  show()
  continue_button.grab_focus()


func _on_continue_pressed() -> void:
  continue_requested.emit()


func _on_menu_pressed() -> void:
  menu_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
  if is_visible_in_tree() and event.is_action_pressed('ui_cancel') and not event.is_echo():
    audio.play_click()
    continue_requested.emit()
    get_viewport().set_input_as_handled()
