class_name HowToPlay
extends PanelContainer

signal closed

@export var scroll: ScrollContainer
@export var audio: UIAudio


func open() -> void:
  scroll.scroll_vertical = 0
  show()
  scroll.grab_focus()


func _on_back_pressed() -> void:
  hide()
  closed.emit()


func _unhandled_input(event: InputEvent) -> void:
  if is_visible_in_tree() and event.is_action_pressed('ui_cancel') and not event.is_echo():
    audio.play_click()
    _on_back_pressed()
    get_viewport().set_input_as_handled()


func _on_scroll_gui_input(event: InputEvent) -> void:
  if not event is InputEventKey or not event.pressed:
    return
  match event.keycode:
    KEY_UP:
      scroll.scroll_vertical -= 48
    KEY_DOWN:
      scroll.scroll_vertical += 48
    KEY_PAGEUP:
      scroll.scroll_vertical -= int(scroll.size.y * 0.9)
    KEY_PAGEDOWN:
      scroll.scroll_vertical += int(scroll.size.y * 0.9)
    KEY_HOME:
      scroll.scroll_vertical = 0
    KEY_END:
      scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
    _:
      return
  scroll.accept_event()
