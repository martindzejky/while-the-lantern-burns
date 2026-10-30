class_name KeyLabel
extends RichTextLabel


func _ready() -> void:
  bbcode_enabled = true
  text = KeyText.format_keys(text)
