class_name CheckpointStorage
extends Node

const SAVE_PATH: String = 'user://progress.json'
const SAVE_VERSION: int = 1
const PROMPT_FLAGS: Array[String] = [
  'has_moved', 'has_picked_lantern', 'has_picked_musket', 'has_dropped_lantern',
  'has_inserted_ball', 'has_loaded', 'has_lit', 'has_aimed', 'has_fired',
]

@export var level_count: int = 3
@export var save_path: String = SAVE_PATH


func load_checkpoint() -> Dictionary:
  if not FileAccess.file_exists(save_path):
    return {}
  var file := FileAccess.open(save_path, FileAccess.READ)
  if file == null:
    push_warning('Could not read progress: %s' % error_string(FileAccess.get_open_error()))
    return {}
  var json := JSON.new()
  var parse_error: Error = json.parse(file.get_as_text())
  if parse_error != OK or not is_valid_checkpoint(json.data):
    push_warning('Ignoring invalid or unsupported progress save.')
    return {}
  return json.data


func save_checkpoint(checkpoint: Dictionary) -> bool:
  var data: Dictionary = checkpoint.duplicate(true)
  data['version'] = SAVE_VERSION
  if not is_valid_checkpoint(data):
    push_error('Cannot save invalid checkpoint.')
    return false
  var directory_error: Error = DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
  if directory_error != OK:
    return _report_save_error(directory_error)
  var file := FileAccess.open(save_path + '.tmp', FileAccess.WRITE)
  if file == null:
    return _report_save_error(FileAccess.get_open_error())
  file.store_string(JSON.stringify(data))
  file.flush()
  var write_error: Error = file.get_error()
  file.close()
  if write_error != OK:
    return _report_save_error(write_error)
  var rename_error: Error = DirAccess.rename_absolute(save_path + '.tmp', save_path)
  if rename_error != OK:
    return _report_save_error(rename_error)
  return true


func clear_checkpoint() -> bool:
  if not FileAccess.file_exists(save_path):
    return true
  var error: Error = DirAccess.remove_absolute(save_path)
  if error != OK:
    return _report_save_error(error)
  return true


func _report_save_error(error: Error) -> bool:
  push_warning('Could not save progress: %s' % error_string(error))
  return false


func is_valid_checkpoint(data: Variant) -> bool:
  if not data is Dictionary or not _is_integer(data.get('version'), SAVE_VERSION, SAVE_VERSION):
    return false
  if not _is_integer(data.get('level_id'), 0, level_count - 1):
    return false
  var player: Variant = data.get('player')
  var prompts: Variant = data.get('prompts')
  if not player is Dictionary or not prompts is Dictionary:
    return false
  var lantern: Variant = player.get('lantern')
  var musket: Variant = player.get('musket')
  if not lantern is Dictionary or not musket is Dictionary:
    return false
  if not _is_number(lantern.get('energy'), 0.0, 100.0):
    return false
  if not lantern.get('carried') is bool or not lantern.get('discovered') is bool:
    return false
  if lantern['carried'] and not lantern['discovered']:
    return false
  if not musket.get('owned') is bool or not _is_integer(musket.get('reload_state'), 0, 2):
    return false
  if not _is_number(musket.get('ramrod_insertion'), 0.0, 1.0):
    return false
  if not _is_number(musket.get('fuse_remaining'), 0.0, 10.0):
    return false
  if musket['fuse_remaining'] > 0.0 and (not musket['owned'] or musket['reload_state'] != 2):
    return false
  for flag: String in PROMPT_FLAGS:
    if not prompts.get(flag) is bool:
      return false
  return _is_integer(prompts.get('charge_count'), 0, 3)


func _is_number(value: Variant, minimum: float, maximum: float) -> bool:
  return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
  return _is_number(value, minimum, maximum) and float(value) == floorf(float(value))
