class_name AudioSettings
extends VBoxContainer

signal closed

const SETTINGS_PATH: String = 'user://audio_settings.json'
const BUSES: Array[StringName] = [&'Master', &'SFX', &'Ambience', &'Music']

@export var sliders: Array[HSlider]
@export var back_button: Button
@export var audio: UIAudio


func _ready() -> void:
  var saved: Dictionary = {}
  if FileAccess.file_exists(SETTINGS_PATH):
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
    if parsed is Dictionary and parsed.get('version') == 1:
      saved = parsed
  for index: int in range(sliders.size()):
    var value: Variant = saved.get(BUSES[index], 1.0)
    var volume: float = clampf(float(value), 0.0, 1.0) if value is float or value is int else 1.0
    sliders[index].set_value_no_signal(volume)
    _apply_volume(BUSES[index], volume)


func open() -> void:
  show()
  sliders[0].grab_focus()


func _on_volume_changed(_value: float) -> void:
  for index: int in range(sliders.size()):
    _apply_volume(BUSES[index], sliders[index].value)


func _apply_volume(bus: StringName, volume: float) -> void:
  var index: int = AudioServer.get_bus_index(bus)
  AudioServer.set_bus_mute(index, volume <= 0.001)
  AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))


func _save() -> void:
  var values: Dictionary = {'version': 1}
  for index: int in range(sliders.size()):
    values[BUSES[index]] = sliders[index].value
  var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
  if file == null:
    push_warning('Could not save audio settings: %s' % error_string(FileAccess.get_open_error()))
    return
  file.store_string(JSON.stringify(values))


func _on_drag_ended(changed: bool) -> void:
  if changed:
    audio.play_click()
    _save()


func _on_back_pressed() -> void:
  _save()
  hide()
  closed.emit()


func _unhandled_input(event: InputEvent) -> void:
  if is_visible_in_tree() and event.is_action_pressed('ui_cancel'):
    audio.play_click()
    _on_back_pressed()
    get_viewport().set_input_as_handled()
