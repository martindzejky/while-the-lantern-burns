extends Node

@export var menu_scene: PackedScene
@export var cave_gameplay_scene: PackedScene
@export var active_screen_container: Node
@export var fade: ColorRect
@export var transition_audio: AudioStreamPlayer
@export var pause_menu: PauseMenu
@export var checkpoint_storage: CheckpointStorage
@export var save_notice: Label
@export var fade_out_duration: float = 1.2
@export var fade_in_duration: float = 1.6

var _screen: Node
var _busy: bool = true
var _checkpoint: Dictionary = {}


func _ready() -> void:
  _checkpoint = checkpoint_storage.load_checkpoint()
  _open_menu()
  await _fade_to(0.0, fade_in_duration)
  _screen.process_mode = Node.PROCESS_MODE_INHERIT
  _busy = false


func _open_menu() -> void:
  var menu: MainMenu = menu_scene.instantiate() as MainMenu
  menu.start_requested.connect(_on_new_game_requested)
  menu.continue_requested.connect(_on_load_requested)
  menu.process_mode = Node.PROCESS_MODE_DISABLED
  _screen = menu
  active_screen_container.add_child(menu)
  menu.set_continue_available(not _checkpoint.is_empty())


func _clear_screen() -> void:
  active_screen_container.remove_child(_screen)
  _screen.queue_free()


func _on_new_game_requested() -> void:
  if not _busy:
    _start_cave_gameplay({})


func _on_load_requested() -> void:
  if not _busy and not _checkpoint.is_empty():
    _start_cave_gameplay(_checkpoint)


func _on_retry_requested() -> void:
  if not _busy:
    _start_cave_gameplay(_checkpoint)


func _start_cave_gameplay(checkpoint: Dictionary) -> void:
  _busy = true
  _screen.process_mode = Node.PROCESS_MODE_DISABLED
  transition_audio.play()
  await _fade_to(1.0, fade_out_duration)
  _clear_screen()
  var cave_gameplay: CaveGameplay = cave_gameplay_scene.instantiate() as CaveGameplay
  cave_gameplay.start_inactive = true
  cave_gameplay.initial_checkpoint = checkpoint.duplicate(true)
  cave_gameplay.pause_requested.connect(_on_pause_requested)
  cave_gameplay.retry_requested.connect(_on_retry_requested)
  cave_gameplay.menu_requested.connect(_on_menu_requested)
  cave_gameplay.level_completed.connect(_on_level_completed)
  cave_gameplay.escaped.connect(_on_escaped)
  _screen = cave_gameplay
  active_screen_container.add_child(cave_gameplay)
  if not cave_gameplay.is_prepared:
    await cave_gameplay.prepared
  _checkpoint = cave_gameplay.get_checkpoint()
  _show_save_result(checkpoint_storage.save_checkpoint(_checkpoint))
  await _fade_to(0.0, fade_in_duration)
  cave_gameplay.set_active(true)
  _busy = false


func _on_level_completed() -> void:
  if _busy:
    return
  var cave_gameplay: CaveGameplay = _screen as CaveGameplay
  var next_checkpoint: Dictionary = cave_gameplay.get_checkpoint()
  next_checkpoint['level_id'] = cave_gameplay.level_id + 1
  _start_cave_gameplay(next_checkpoint)


func _on_escaped() -> void:
  _checkpoint = {}
  _show_save_result(checkpoint_storage.clear_checkpoint())


func _show_save_result(saved: bool) -> void:
  save_notice.visible = not saved


func _on_menu_requested() -> void:
  if _busy:
    return
  _busy = true
  pause_menu.hide()
  get_tree().paused = false
  _screen.process_mode = Node.PROCESS_MODE_DISABLED
  transition_audio.play()
  await _fade_to(1.0, fade_out_duration)
  _clear_screen()
  _open_menu()
  await _fade_to(0.0, fade_in_duration)
  _screen.process_mode = Node.PROCESS_MODE_INHERIT
  _busy = false


func _on_pause_requested() -> void:
  if _busy:
    return
  get_tree().paused = true
  pause_menu.open()


func _on_continue_requested() -> void:
  pause_menu.hide()
  get_tree().paused = false


func _fade_to(alpha: float, duration: float) -> void:
  fade.show()
  var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
  tween.tween_property(fade, 'color:a', alpha, duration)
  await tween.finished
  if is_zero_approx(alpha):
    fade.hide()
