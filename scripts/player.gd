class_name Player
extends CharacterBody3D

signal movement_started
signal interaction_range_changed
signal died
signal light_changed(lit: bool)
signal darkness_progress_changed(progress: float)
signal darkness_killed
signal ramrod_drag_changed(dragging: bool)

@export var rig: CharacterRig
@export var musket: Musket
@export var lantern: Lantern
@export var drop_slot: Marker3D
@export var aim_line: Sprite3D
@export var light_sensor: LightSensor
@export var body_audio: AudioStreamPlayer3D
@export var footstep_audio: AudioStreamPlayer3D
@export var audio_listener: AudioListener3D
@export var aim_height: float = 0.7
@export var pickup_radius: float = 1.5
@export var speed: float = 4.0
@export_range(0.0, 1.0, 0.05) var aim_speed_multiplier: float = 0.5
@export var ramrod_drag_distance: float = 150.0
@export var darkness_grace: float = 2.0

var is_dead: bool = false
var darkness_progress: float = 0.0
var is_lit: bool:
  get:
    return light_sensor.is_lit
var _was_moving: bool = false
var _lantern_in_reach: bool = false
var _musket_in_reach: bool = false
var _darkness_timer: Timer = Timer.new()
var _item_parent: Node
var _shot_requested: bool = false
var _fuse_shot_requested: bool = false
var _dragging_ramrod: bool = false
var _locked_aim_target: Vector3
var _darkness_allowed: bool = true
var _darkness_enabled: bool = false


func _ready() -> void:
  audio_listener.make_current()
  _item_parent = lantern.get_parent()
  _darkness_timer.wait_time = darkness_grace
  _darkness_timer.timeout.connect(_on_darkness_expired)
  _darkness_timer.one_shot = true
  _darkness_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
  add_child(_darkness_timer)


func _process(_delta: float) -> void:
  _update_equipment()


func _notification(what: int) -> void:
  if what == NOTIFICATION_PAUSED and is_node_ready():
    _set_dragging_ramrod(false)


func _input(event: InputEvent) -> void:
  if musket.is_trigger_pending:
    get_viewport().set_input_as_handled()
    return
  if not _dragging_ramrod:
    return
  if event is InputEventMouseMotion:
    var previous_insertion := musket.ramrod_insertion
    musket.move_ramrod(event.relative.y / ramrod_drag_distance)
    if (
      previous_insertion > 0.0 and musket.reload_state == Musket.ReloadState.LOADED
      and musket.ramrod_insertion == 0.0
    ):
      _set_dragging_ramrod(false)
    get_viewport().set_input_as_handled()
  elif event.is_action_released('fire_musket'):
    _set_dragging_ramrod(false)
    get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
  if event.is_echo():
    return

  if event.is_action_pressed('interact'):
    _interact()
  elif event.is_action_pressed('ignite_musket'):
    if (
      not lantern.is_carried and can_reach(lantern)
      and lantern.can_light_fuse()
      and musket.reload_state == Musket.ReloadState.LOADED
    ):
      _set_dragging_ramrod(false)
      musket.ignite()
  elif event.is_action_pressed('fire_musket'):
    if _aiming_requested():
      _update_equipment()
      if musket.pull_trigger():
        _locked_aim_target = _get_aim_target(get_viewport().get_mouse_position())
        if _locked_aim_target.is_equal_approx(global_position):
          _locked_aim_target += Vector3.LEFT if rig.is_facing_left() else Vector3.RIGHT
        velocity = Vector3.ZERO
        rig.set_frozen(true)
  else:
    return
  get_viewport().set_input_as_handled()


func _on_light_sensor_light_changed(lit: bool) -> void:
  if not is_dead and _darkness_enabled:
    if lit:
      _darkness_timer.stop()
    else:
      _darkness_timer.start()
    _set_darkness_progress(0.0)
  light_changed.emit(lit)


func set_darkness_enabled(enabled: bool) -> void:
  _darkness_allowed = enabled
  _darkness_enabled = false
  _darkness_timer.stop()
  _set_darkness_progress(0.0)


func _on_light_sensor_exposure_changed(_exposure: float) -> void:
  # wait for a fresh light sample after loading before starting the grace timer.
  if not _darkness_allowed or _darkness_enabled or is_dead:
    return
  _darkness_enabled = true
  if not is_lit:
    _darkness_timer.start()


func _set_darkness_progress(progress: float) -> void:
  if is_equal_approx(darkness_progress, progress):
    return
  darkness_progress = progress
  darkness_progress_changed.emit(progress)


func _on_lantern_pressed() -> void:
  if not is_dead and lantern.is_carried:
    lantern.charge()


func _on_musket_fuse_expired() -> void:
  if is_dead:
    musket.fire_upwards()
  else:
    _fuse_shot_requested = true


func _on_musket_trigger_ready() -> void:
  if is_dead:
    musket.fire_upwards()
  else:
    _shot_requested = true


func _on_musket_fired(hit: Dictionary) -> void:
  if not is_dead:
    rig.set_frozen(false)
  var enemy := hit.get('collider') as Enemy
  if enemy:
    enemy.take_shot()


func take_bite() -> void:
  die()


func _on_darkness_expired() -> void:
  if is_dead:
    return
  darkness_killed.emit()
  die()


func die() -> void:
  if is_dead:
    return
  is_dead = true
  _darkness_timer.stop()
  velocity = Vector3.ZERO
  _set_dragging_ramrod(false)
  _shot_requested = false
  _fuse_shot_requested = false
  musket.set_aiming(false)
  rig.show_death()
  body_audio.play()
  _drop_equipment()
  aim_line.hide()
  set_process(false)
  set_physics_process(false)
  set_process_input(false)
  set_process_unhandled_input(false)
  died.emit()


func _drop_equipment() -> void:
  if lantern.is_carried:
    _drop_lantern()
  if musket.is_owned:
    musket.reparent(_item_parent)
    musket.global_transform = Transform3D(Basis.IDENTITY, global_position * 2.0 - _get_drop_position())
    musket.drop()


func _drop_lantern() -> void:
  lantern.reparent(_item_parent)
  lantern.global_transform = Transform3D(Basis.IDENTITY, _get_drop_position())
  lantern.set_carried(false)


func _get_drop_position() -> Vector3:
  var offset := drop_slot.global_position - global_position
  if rig.is_facing_left():
    offset.x = -offset.x
  return global_position + offset


func _on_barrel_pressed() -> void:
  if not is_dead and not lantern.is_carried:
    musket.insert_ball()


func _on_ramrod_gui_input(event: InputEvent) -> void:
  if not is_dead and event.is_action_pressed('fire_musket') and not lantern.is_carried:
    _set_dragging_ramrod(musket.can_use_ramrod())


func _set_dragging_ramrod(dragging: bool) -> void:
  if _dragging_ramrod == dragging:
    return
  _dragging_ramrod = dragging
  musket.set_ramrod_dragging(dragging)
  ramrod_drag_changed.emit(dragging)
  if not dragging:
    musket.cancel_ramrod()


func _interact() -> void:
  _set_dragging_ramrod(false)
  if lantern.is_carried:
    _drop_lantern()
  elif not musket.is_owned and can_reach(musket):
    _attach(musket, rig.get_back_slot())
    musket.equip()
  elif not musket.is_lit and can_reach(lantern):
    lantern.set_carried(true)
    _attach(lantern, rig.get_right_hand_slot())
    _align_grip(lantern, lantern.grip, rig.get_right_hand_slot())
  _update_equipment()


func can_reach(item: Node3D) -> bool:
  return global_position.distance_squared_to(item.global_position) <= pickup_radius * pickup_radius


func _attach(item: Node3D, slot: Marker3D) -> void:
  item.reparent(slot, false)
  item.transform = Transform3D.IDENTITY


func _align_grip(item: Node3D, grip: Marker3D, slot: Marker3D) -> void:
  item.global_position += slot.global_position - grip.global_position


func _update_equipment() -> void:
  if musket.is_trigger_pending:
    return
  var aiming := _aiming_requested()
  musket.set_aiming(aiming)
  var pose := CharacterRig.EquipmentPose.IDLE
  if lantern.is_carried:
    pose = CharacterRig.EquipmentPose.LANTERN
  elif aiming:
    pose = CharacterRig.EquipmentPose.MUSKET_AIM
  elif musket.is_lit:
    pose = CharacterRig.EquipmentPose.MUSKET_READY
  rig.set_equipment_pose(pose)
  if aiming:
    var mouse := get_viewport().get_mouse_position()
    var target := _get_aim_target(mouse)
    rig.set_facing(Vector2(target.x - global_position.x, target.z - global_position.z))
    var camera := get_viewport().get_camera_3d()
    rig.set_aim_direction(mouse - camera.unproject_position(rig.get_aim_origin()))
  if not musket.is_owned:
    return
  var in_hands := aiming or musket.is_lit
  var slot := rig.get_left_hand_slot() if in_hands else rig.get_back_slot()
  if musket.get_parent() != slot:
    _attach(musket, slot)
  if in_hands:
    musket.set_held_angle(rig.get_musket_angle())
    _align_grip(musket, musket.rear_grip, slot)


func _aiming_requested() -> bool:
  return (
    not is_dead and musket.is_owned and not lantern.is_carried and not _dragging_ramrod
    and (musket.is_trigger_pending or Input.is_action_pressed('aim_musket'))
  )


func is_aiming() -> bool:
  return _aiming_requested()


func get_aim_target() -> Vector3:
  if musket.is_trigger_pending:
    return _locked_aim_target
  return _get_aim_target(get_viewport().get_mouse_position())


func _update_aim_line(target: Vector3) -> void:
  var direction := global_position.direction_to(target)
  if direction.is_zero_approx():
    aim_line.hide()
    return
  var length := musket.shot_range
  aim_line.global_position = global_position + direction * length * 0.5 + Vector3.UP * 0.025
  aim_line.global_basis = Basis(direction, Vector3.UP.cross(direction), Vector3.UP).scaled_local(
    Vector3(length, 0.025, 1.0)
  )


func _get_aim_target(mouse: Vector2) -> Vector3:
  var camera := get_viewport().get_camera_3d()
  var origin := camera.project_ray_origin(mouse)
  var direction := camera.project_ray_normal(mouse)
  var point: Variant = Plane(Vector3.UP, global_position.y + aim_height).intersects_ray(origin, direction)
  if point == null:
    return global_position
  var target: Vector3 = point
  target.y = global_position.y
  return global_position + (target - global_position).limit_length(musket.shot_range)


func _physics_process(_delta: float) -> void:
  if not _darkness_timer.is_stopped():
    _set_darkness_progress(clampf(1.0 - _darkness_timer.time_left / darkness_grace, 0.0, 1.0))
  if musket.is_trigger_pending:
    velocity = Vector3.ZERO
  else:
    var aiming := _aiming_requested()
    var direction := Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
    var movement_speed := speed * aim_speed_multiplier if aiming else speed
    velocity = Vector3(direction.x, 0.0, direction.y) * movement_speed
    var previous_position := global_position
    move_and_slide()
    var moving := not global_position.is_equal_approx(previous_position)
    if moving and not _was_moving:
      movement_started.emit()
    _was_moving = moving
    var lantern_in_reach := can_reach(lantern)
    var musket_in_reach := can_reach(musket)
    if lantern_in_reach != _lantern_in_reach or musket_in_reach != _musket_in_reach:
      _lantern_in_reach = lantern_in_reach
      _musket_in_reach = musket_in_reach
      interaction_range_changed.emit()
    if not _aiming_requested():
      rig.set_facing(Vector2(velocity.x, velocity.z))
    rig.set_moving(not velocity.is_zero_approx())
  _update_equipment()
  aim_line.visible = musket.is_aiming
  var target := global_position
  if musket.is_aiming:
    target = _locked_aim_target if musket.is_trigger_pending else _get_aim_target(get_viewport().get_mouse_position())
    _update_aim_line(target)
  if _shot_requested or _fuse_shot_requested:
    _shot_requested = false
    if musket.is_aiming:
      musket.fire(global_position, target, get_rid())
    if _fuse_shot_requested and musket.is_lit:
      musket.fire_upwards()
    _fuse_shot_requested = false
    _update_equipment()


func _on_rig_stepped() -> void:
  if not is_dead and not velocity.is_zero_approx() and not musket.is_trigger_pending:
    footstep_audio.play()


func get_checkpoint() -> Dictionary:
  return {
    'lantern': lantern.get_checkpoint(),
    'musket': musket.get_checkpoint(),
  }


func restore_checkpoint(
  data: Dictionary, entry: Vector3, lantern_position: Vector3, musket_position: Vector3
) -> void:
  global_position = entry
  velocity = Vector3.ZERO
  lantern.restore_checkpoint(data['lantern'])
  musket.restore_checkpoint(data['musket'])
  if lantern.is_carried:
    _attach(lantern, rig.get_right_hand_slot())
    _align_grip(lantern, lantern.grip, rig.get_right_hand_slot())
  else:
    lantern.reparent(_item_parent)
    lantern.global_transform = Transform3D(Basis.IDENTITY, lantern_position)
  if musket.is_owned:
    _attach(musket, rig.get_back_slot())
  else:
    musket.reparent(_item_parent)
    musket.global_transform = Transform3D(Basis.IDENTITY, musket_position)
  _update_equipment()
  interaction_range_changed.emit()
