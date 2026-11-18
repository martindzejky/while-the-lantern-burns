class_name VictoryScreen
extends CanvasLayer

signal menu_requested

@export var panel: Control
@export var background: ColorRect
@export var title: Label
@export var menu_button: Button


func open() -> void:
  show()
  background.color.a = 0.0
  title.modulate.a = 0.0
  menu_button.modulate.a = 0.0
  menu_button.disabled = true
  var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  tween.tween_property(background, 'color:a', 1.0, 2.0)
  tween.tween_interval(0.25)
  tween.tween_property(title, 'modulate:a', 1.0, 0.7)
  tween.tween_property(menu_button, 'modulate:a', 1.0, 0.4)
  await tween.finished
  menu_button.disabled = false
  menu_button.grab_focus()


func _on_menu_pressed() -> void:
  menu_requested.emit()
