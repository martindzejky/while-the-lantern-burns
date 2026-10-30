extends SceneTree

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  var progress := GameProgress.new()
  progress.save_path = 'user://checkpoint-test-%d.json' % OS.get_process_id()
  var checkpoint := _checkpoint()
  _expect(progress.is_valid_checkpoint(checkpoint), 'valid checkpoint')
  _expect(progress.save_checkpoint(checkpoint), 'save checkpoint')
  var loaded := progress.load_checkpoint()
  _expect(progress.is_valid_checkpoint(loaded), 'JSON numbers validate after roundtrip')
  _expect(loaded['level_id'] == 1, 'level roundtrip')
  _expect(loaded['player']['lantern']['energy'] == 42.5, 'energy roundtrip')
  _expect(loaded['player']['musket']['ramrod_insertion'] == 0.75, 'ramrod roundtrip')
  _expect(loaded['player']['musket']['fuse_remaining'] == 6.25, 'fuse roundtrip')
  _expect(loaded['prompts']['has_moved'] is bool, 'booleans remain booleans')
  _expect(loaded['prompts']['has_moved'], 'tutorial roundtrip')
  _expect(not FileAccess.file_exists(progress.save_path + '.tmp'), 'temporary file renamed')

  for value: Variant in [null, [], 'checkpoint', {}, {'version': 1}]:
    _expect(not progress.is_valid_checkpoint(value), 'reject incomplete checkpoint')
  for value: Variant in [null, 0, 2, '1', true]:
    var invalid := checkpoint.duplicate(true)
    invalid['version'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject unsupported version %s' % str(value))
  for value: Variant in [-1, 3, 0.5, '1', true, NAN, INF]:
    var invalid := checkpoint.duplicate(true)
    invalid['level_id'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid level %s' % str(value))
  for value: Variant in [-0.1, 100.1, NAN, INF, true, '42']:
    var invalid := checkpoint.duplicate(true)
    invalid['player']['lantern']['energy'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid energy %s' % str(value))
  for value: Variant in [-0.1, 1.1, NAN, true]:
    var invalid := checkpoint.duplicate(true)
    invalid['player']['musket']['ramrod_insertion'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid ramrod')
  for value: Variant in [-0.1, 10.1, NAN, true]:
    var invalid := checkpoint.duplicate(true)
    invalid['player']['musket']['fuse_remaining'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid fuse')
  for value: Variant in [-1, 3, 0.5, true]:
    var invalid := checkpoint.duplicate(true)
    invalid['player']['musket']['reload_state'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid reload state')
  var invalid := checkpoint.duplicate(true)
  invalid['player']['lantern']['carried'] = true
  invalid['player']['lantern']['discovered'] = false
  _expect(not progress.is_valid_checkpoint(invalid), 'carried lantern must be discovered')
  invalid = checkpoint.duplicate(true)
  invalid['player']['musket']['owned'] = false
  _expect(not progress.is_valid_checkpoint(invalid), 'burning musket must be owned')
  invalid = checkpoint.duplicate(true)
  invalid['player']['musket']['reload_state'] = 1
  _expect(not progress.is_valid_checkpoint(invalid), 'burning musket must be loaded')
  for flag: String in GameProgress.PROMPT_FLAGS:
    invalid = checkpoint.duplicate(true)
    invalid['prompts'][flag] = 1
    _expect(not progress.is_valid_checkpoint(invalid), 'reject nonboolean prompt ' + flag)
  for value: Variant in [-1, 4, 1.5, true]:
    invalid = checkpoint.duplicate(true)
    invalid['prompts']['charge_count'] = value
    _expect(not progress.is_valid_checkpoint(invalid), 'reject invalid charge count')

  _write_text(progress.save_path, '{broken JSON')
  _expect(progress.load_checkpoint().is_empty(), 'malformed file falls back to new game')
  _write_text(progress.save_path, '{}')
  _expect(progress.load_checkpoint().is_empty(), 'incomplete file falls back to new game')
  _expect(progress.clear_checkpoint(), 'clear checkpoint')
  _expect(progress.load_checkpoint().is_empty(), 'absent file returns empty checkpoint')
  _expect(progress.clear_checkpoint(), 'clear absent checkpoint')

  # a file cannot be used as a directory; exercise a real filesystem write failure.
  var blocker := progress.save_path + '.blocker'
  _write_text(blocker, 'block')
  progress.save_path = blocker.path_join('progress.json')
  _expect(not progress.save_checkpoint(checkpoint), 'write failure reports false')
  _expect(progress.load_checkpoint().is_empty(), 'unreadable path returns empty checkpoint')
  DirAccess.remove_absolute(blocker)
  progress.free()
  print('Checkpoint tests: %d checks, %d failures' % [_checks, _failures])
  for audio: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio as AudioStreamPlayer).stop()
  await create_timer(0.1).timeout
  quit(1 if _failures > 0 else 0)


func _checkpoint() -> Dictionary:
  var prompts: Dictionary = {'charge_count': 2}
  for flag: String in GameProgress.PROMPT_FLAGS:
    prompts[flag] = true
  return {
    'version': GameProgress.SAVE_VERSION,
    'level_id': 1,
    'player': {
      'lantern': {'energy': 42.5, 'carried': false, 'discovered': true},
      'musket': {'owned': true, 'reload_state': 2, 'ramrod_insertion': 0.75, 'fuse_remaining': 6.25},
    },
    'prompts': prompts,
  }


func _write_text(path: String, contents: String) -> void:
  var file := FileAccess.open(path, FileAccess.WRITE)
  assert(file != null)
  file.store_string(contents)
  file.close()


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error('FAILED: ' + message)
