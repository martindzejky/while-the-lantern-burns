extends Node

@export var menu_scene: PackedScene
@export var game_scene: PackedScene
@export var screen_host: Node
@export var fade: ColorRect
@export var transition_audio: AudioStreamPlayer
@export var pause_menu: PauseMenu
@export var progress: GameProgress
@export var save_notice: Label
@export var fade_out_duration: float = 1.2
@export var fade_in_duration: float = 1.6

var _screen: Node
var _busy: bool = true
var _checkpoint: Dictionary = {}


func _ready() -> void:
  _checkpoint = progress.load_checkpoint()
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
  screen_host.add_child(menu)
  menu.set_continue_available(not _checkpoint.is_empty())


func _clear_screen() -> void:
  screen_host.remove_child(_screen)
  _screen.queue_free()


func _on_new_game_requested() -> void:
  if not _busy:
    _start_game({})


func _on_load_requested() -> void:
  if not _busy and not _checkpoint.is_empty():
    _start_game(_checkpoint)


func _on_retry_requested() -> void:
  if not _busy:
    _start_game(_checkpoint)


func _start_game(checkpoint: Dictionary) -> void:
  _busy = true
  _screen.process_mode = Node.PROCESS_MODE_DISABLED
  transition_audio.play()
  await _fade_to(1.0, fade_out_duration)
  _clear_screen()
  var game: GameSession = game_scene.instantiate() as GameSession
  game.start_inactive = true
  game.initial_checkpoint = checkpoint.duplicate(true)
  game.pause_requested.connect(_on_pause_requested)
  game.retry_requested.connect(_on_retry_requested)
  game.menu_requested.connect(_on_menu_requested)
  game.level_completed.connect(_on_level_completed)
  game.escaped.connect(_on_escaped)
  _screen = game
  screen_host.add_child(game)
  if not game.is_prepared:
    await game.prepared
  _checkpoint = game.get_checkpoint()
  _show_save_result(progress.save_checkpoint(_checkpoint))
  await _fade_to(0.0, fade_in_duration)
  game.set_active(true)
  _busy = false


func _on_level_completed() -> void:
  if _busy:
    return
  var game: GameSession = _screen as GameSession
  var next_checkpoint: Dictionary = game.get_checkpoint()
  next_checkpoint['level_id'] = game.level_id + 1
  _start_game(next_checkpoint)


func _on_escaped() -> void:
  _checkpoint = {}
  _show_save_result(progress.clear_checkpoint())


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
