class_name KeyText
extends RefCounted


static func format_keys(value: String) -> String:
  return value.replace('[key]', '[b][color=#ffe16b]').replace('[/key]', '[/color][/b]')
