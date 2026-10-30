extends Control

@export var player: Player
@export var lantern: Lantern
@export var musket: Musket
@export var movement: Node3D
@export var movement_text: HintLabel
@export var instruction: HintLabel
@export var context: Node3D
@export var context_text: HintLabel

var _hud_layer: CanvasLayer
var _context_host: Node
var _has_moved: bool = false
var _charge_count: int = 0
var _has_picked_lantern: bool = false
var _has_picked_musket: bool = false
var _has_dropped_lantern: bool = false
var _has_inserted_ball: bool = false
var _has_loaded: bool = false
var _has_lit: bool = false
var _has_aimed: bool = false
var _has_fired: bool = false


func _ready() -> void:
  _context_host = context.get_parent()
  _hud_layer = get_canvas_layer_node()
  _hud_layer.visibility_changed.connect(_on_visibility_changed)
  movement.global_position = player.global_position + Vector3(0, 2.4, 0)
  _has_picked_lantern = lantern.is_carried
  _has_picked_musket = musket.is_owned
  _refresh()


func _on_movement_started() -> void:
  _has_moved = true
  movement_text.set_message('')


func _on_lantern_charged(stroke: float) -> void:
  if stroke >= 0.5:
    _charge_count += 1
  _refresh()


func _on_carried_changed(carried: bool) -> void:
  _has_dropped_lantern = _has_dropped_lantern or (_has_picked_lantern and not carried)
  _has_picked_lantern = _has_picked_lantern or carried
  _refresh()


func _on_equipped() -> void:
  _has_picked_musket = true
  _refresh()


func _on_reload_changed() -> void:
  _has_inserted_ball = _has_inserted_ball or musket.reload_state != Musket.ReloadState.EMPTY
  _has_loaded = _has_loaded or musket.reload_state == Musket.ReloadState.LOADED
  _refresh()


func _on_lit_changed(lit: bool) -> void:
  _has_lit = _has_lit or lit
  _refresh()


func _on_aiming_changed(aiming: bool) -> void:
  _has_aimed = _has_aimed or (musket.is_lit and aiming)
  _refresh()


func _on_musket_fired(_hit: Dictionary) -> void:
  _has_fired = true
  _refresh()


func _on_visibility_changed() -> void:
  if not is_node_ready():
    return
  var active := is_visible_in_tree() and _hud_layer.visible and not player.is_dead
  movement.visible = active
  context.visible = active
  if not active:
    movement_text.reset_hint()
    context_text.reset_hint()
    instruction.reset_hint()
  else:
    _refresh()


func _refresh() -> void:
  if player.is_dead or not is_visible_in_tree() or not _hud_layer.visible:
    return
  movement_text.set_message('' if _has_moved else '[key]WASD[/key] / [key]Arrow keys[/key]\nMove')
  var next_instruction := _get_instruction()
  instruction.set_message(next_instruction)
  context_text.set_message(_get_context())


func _place_context(target: Node3D, height: float) -> void:
  var host: Node = player if target == player else _context_host
  if context.get_parent() != host:
    context.reparent(host, false)
  context.transform = Transform3D.IDENTITY
  if target == player:
    context.position = Vector3.UP * height
  else:
    context.global_position = target.global_position + Vector3.UP * height


func _get_context() -> String:
  if musket.is_trigger_pending:
    return ''
  if lantern.is_carried:
    if not musket.is_owned and player.can_reach(musket):
      _place_context(player, 2.4)
      return '[key]E[/key] / [key]Enter[/key]\nPut down the lantern first'
    if musket.is_owned and not _has_dropped_lantern:
      _place_context(player, 2.4)
      return '[key]E[/key] / [key]Enter[/key]\nPut down the lantern'
    return ''
  if not musket.is_owned and not _has_picked_musket and player.can_reach(musket):
    _place_context(musket, 1.3)
    return '[key]E[/key] / [key]Enter[/key]\nPick up the musket'
  if not musket.is_lit and player.can_reach(lantern):
    if musket.is_owned and musket.reload_state == Musket.ReloadState.LOADED and not _has_lit:
      _place_context(lantern, 1.5)
      if lantern.can_light_fuse():
        return '[key]R[/key] / [key]Shift[/key] / [key]Space[/key]\nLight the fuse'
      return 'Pick up and charge the lantern first'
    if not _has_picked_lantern:
      _place_context(lantern, 1.5)
      return '[key]E[/key] / [key]Enter[/key]\nPick up the lantern'
  return ''


func _get_instruction() -> String:
  if musket.is_lit:
    if not _has_aimed:
      return 'Hold [key]Right mouse[/key] to aim'
    if not _has_fired:
      return '[key]Left click[/key] to fire'
    return ''
  if lantern.is_carried:
    if _charge_count < 3:
      return 'Hover over the lantern\n[key]Left click[/key] its handle to charge it\nLet it return, then pump again'
    return ''
  if musket.is_owned:
    match musket.reload_state:
      Musket.ReloadState.EMPTY:
        if not _has_inserted_ball:
          return 'Hover over the musket\n[key]Left click[/key] the barrel opening'
      Musket.ReloadState.BALL_INSERTED:
        if not _has_loaded:
          return 'Hold [key]Left mouse[/key] on the rod\nDrag it all the way down'
      Musket.ReloadState.LOADED:
        if not _has_lit:
          return 'Stand beside your charged lantern\nPut it down to light the fuse'
  return ''


func _on_instruction_shown() -> void:
  instruction.anchor_left = 0.56 if lantern.is_carried else 0.14
  instruction.anchor_right = 0.86 if lantern.is_carried else 0.44
