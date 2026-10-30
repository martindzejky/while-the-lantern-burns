class_name HintLabel
extends RichTextLabel

signal message_shown

@export var render_viewport: SubViewport
@export var fade_duration: float = 0.25
@export var dismiss_delay: float = 3.0
@export var dismiss_duration: float = 0.8

var _message: String = ''
var _transition: Tween


func _ready() -> void:
  bbcode_enabled = true
  modulate.a = 0.0


func set_message(message: String, linger: bool = true) -> void:
  if message == _message:
    return
  if message.is_empty():
    _replace_text(_message)
  _message = message
  if render_viewport:
    render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  if _transition:
    _transition.kill()
  _transition = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  if message.is_empty():
    if linger:
      if modulate.a < 1.0:
        _transition.tween_property(self, 'modulate:a', 1.0, fade_duration)
      _transition.tween_interval(dismiss_delay)
    _transition.tween_property(self, 'modulate:a', 0.0, dismiss_duration)
  else:
    if modulate.a > 0.0:
      _transition.tween_property(self, 'modulate:a', 0.0, fade_duration)
    _transition.tween_callback(_show_message.bind(message))
    _transition.tween_property(self, 'modulate:a', 1.0, fade_duration)
  _transition.tween_callback(_finish_rendering)


func reset_hint() -> void:
  if _transition:
    _transition.kill()
  _message = ''
  text = ''
  modulate.a = 0.0
  _finish_rendering()


func _finish_rendering() -> void:
  if render_viewport:
    render_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _replace_text(message: String) -> void:
  text = KeyText.format_keys(message)


func _show_message(message: String) -> void:
  _replace_text(message)
  message_shown.emit()
