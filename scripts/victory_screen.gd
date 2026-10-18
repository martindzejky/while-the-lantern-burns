class_name VictoryScreen
extends CanvasLayer

signal menu_requested

@export var panel: Control
@export var menu_button: Button


func open() -> void:
  show()
  panel.modulate.a = 0.0
  var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  tween.tween_property(panel, 'modulate:a', 1.0, 1.2)
  menu_button.grab_focus()


func _on_menu_pressed() -> void:
  menu_requested.emit()
