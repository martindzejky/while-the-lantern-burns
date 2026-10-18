extends Control

@export var player: Player
@export var lantern: Lantern
@export var musket: Musket
@export var movement: Label
@export var instruction: Label
@export var context: Label

var _refresh_timer: Timer = Timer.new()
var _start_position: Vector3
var _has_moved: bool = false
var _has_charged: bool = false


func _ready() -> void:
  _start_position = player.global_position
  lantern.lever_changed.connect(_on_lever_changed)
  _refresh_timer.wait_time = 0.12
  _refresh_timer.timeout.connect(_refresh)
  add_child(_refresh_timer)
  _refresh_timer.start()
  _refresh()


func _on_lever_changed(openness: float) -> void:
  if openness < 0.1 and lantern.is_carried:
    _has_charged = true


func _refresh() -> void:
  visible = not player.is_dead and player.process_mode != Node.PROCESS_MODE_DISABLED
  if not visible:
    return
  if player.global_position.distance_squared_to(_start_position) > 9.0:
    _has_moved = true
  movement.visible = not _has_moved
  instruction.text = _get_instruction()
  context.text = _get_context()


func _near(item: Node3D) -> bool:
  return player.global_position.distance_squared_to(item.global_position) <= player.pickup_radius * player.pickup_radius


func _get_context() -> String:
  if musket.is_trigger_pending:
    return ''
  if lantern.is_carried:
    if not musket.is_owned and _near(musket):
      return 'E / ENTER   Put down the lantern, then pick up the musket'
    return 'E / ENTER   Put down the lantern'
  if not musket.is_owned and _near(musket):
    return 'E / ENTER   Pick up the musket'
  if not musket.is_lit and _near(lantern):
    if musket.is_owned and musket.reload_state == Musket.ReloadState.LOADED:
      if lantern.energy >= lantern.max_energy * 0.2:
        return 'R / SHIFT / SPACE   Light the fuse     ·     E / ENTER   Pick up lantern'
      return 'E / ENTER   Pick up and charge the lantern first'
    return 'E / ENTER   Pick up the lantern'
  return ''


func _get_instruction() -> String:
  if musket.is_lit:
    return 'Hold RIGHT MOUSE to aim · LEFT CLICK to fire\nThe burning fuse will fire on its own if you wait'
  if lantern.is_carried:
    if not _has_charged or lantern.energy < lantern.max_energy * 0.3:
      return 'Hover over the lantern on the RIGHT\nCLICK its handle repeatedly to charge the light'
    if musket.is_owned:
      if musket.reload_state == Musket.ReloadState.LOADED:
        return 'Put down the charged lantern, then stand beside it\nR / SHIFT / SPACE lights the musket fuse'
      return 'Put down the lantern to prepare your musket'
    return ''
  if musket.is_owned:
    match musket.reload_state:
      Musket.ReloadState.EMPTY:
        return 'Hover over the musket on the LEFT\nCLICK the barrel opening to insert a ball'
      Musket.ReloadState.BALL_INSERTED:
        return 'HOLD the rod beside the musket and DRAG DOWN\nPush it all the way into the barrel to load'
      Musket.ReloadState.LOADED:
        return 'Musket loaded · Stand beside a charged lantern\nR / SHIFT / SPACE lights the fuse'
  if not player.is_lit:
    return 'Return to the light — the darkness is deadly'
  return ''
