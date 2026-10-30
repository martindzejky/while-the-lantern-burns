class_name HowToPlay
extends PanelContainer

signal closed

@export var scroll: ScrollContainer
@export var audio: UIAudio


func _ready() -> void:
  get_parent().resized.connect(_update_content_widths)
  scroll.resized.connect(_update_content_widths)
  _update_content_widths()


func _update_content_widths() -> void:
  var parent: Control = get_parent()
  var panel_width := parent.size.x * (anchor_right - anchor_left) + offset_right - offset_left
  var padding := get_theme_stylebox('panel').get_minimum_size().x
  var available_width := maxf(0.0, panel_width - padding - scroll.get_v_scroll_bar().size.x)
  for child: Control in scroll.get_child(0).get_children():
    var max_width := 720.0 if child is TextureRect else 600.0
    child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    child.custom_minimum_size.x = minf(available_width, max_width)


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
