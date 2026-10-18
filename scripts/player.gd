class_name Player
extends CharacterBody3D

signal died
signal light_changed(lit: bool)
signal ramrod_drag_changed(dragging: bool)

@export var flip: Node3D
@export var musket: Musket
@export var lantern: Lantern
@export var lantern_slot: Marker3D
@export var drop_slot: Marker3D
@export var musket_back_slot: Marker3D
@export var musket_front_slot: Marker3D
@export var musket_aim_slot: Marker3D
@export var aim_line: Sprite3D
@export var light_sensor: LightSensor
@export var aim_height: float = 0.7
@export var pickup_radius: float = 1.5
@export var speed: float = 4.0
@export var dash_speed: float = 14.0
@export var dash_duration: float = 0.18
@export var dash_recovery: float = 0.5
@export var dash_cooldown: float = 4.0
@export var ramrod_drag_distance: float = 150.0
@export var darkness_grace: float = 2.0

var is_dead: bool = false
var is_lit: bool:
  get:
    return light_sensor.is_lit
var _last_direction: Vector2 = Vector2.DOWN
var _dash_direction: Vector2 = Vector2.DOWN
var _dash_timer: Timer = Timer.new()
var _recovery_timer: Timer = Timer.new()
var _cooldown_timer: Timer = Timer.new()
var _darkness_timer: Timer = Timer.new()
var _item_parent: Node
var _shot_requested: bool = false
var _fuse_shot_requested: bool = false
var _dragging_ramrod: bool = false


func _ready() -> void:
  _item_parent = lantern.get_parent()
  _dash_timer.wait_time = dash_duration
  _recovery_timer.wait_time = dash_recovery
  _cooldown_timer.wait_time = dash_cooldown
  _darkness_timer.wait_time = darkness_grace
  _dash_timer.timeout.connect(_on_dash_timer_timeout)
  _darkness_timer.timeout.connect(die)
  var timers: Array[Timer] = [_dash_timer, _recovery_timer, _cooldown_timer, _darkness_timer]
  for timer: Timer in timers:
    timer.one_shot = true
    timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
    add_child(timer)
  if not is_lit:
    _darkness_timer.start()


func _process(_delta: float) -> void:
  var facing := velocity.x
  if _aiming_requested():
    var camera := get_viewport().get_camera_3d()
    facing = get_viewport().get_mouse_position().x - camera.unproject_position(global_position).x
  if not is_zero_approx(facing):
    flip.scale.x = -1.0 if facing < 0.0 else 1.0
  _update_equipment()


func _input(event: InputEvent) -> void:
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
      not lantern.is_carried and _within_reach(lantern)
      and lantern.energy >= lantern.max_energy * 0.3
      and musket.reload_state == Musket.ReloadState.LOADED
    ):
      _set_dragging_ramrod(false)
      musket.ignite()
  elif event.is_action_pressed('fire_musket'):
    _shot_requested = _aiming_requested()
  elif event.is_action_pressed('dash'):
    _dash()
  else:
    return
  get_viewport().set_input_as_handled()


func _on_light_sensor_light_changed(lit: bool) -> void:
  if not is_dead:
    if lit:
      _darkness_timer.stop()
    else:
      _darkness_timer.start()
  light_changed.emit(lit)


func _on_lantern_pressed() -> void:
  if not is_dead and lantern.is_carried:
    lantern.charge()


func _on_musket_fuse_expired() -> void:
  if is_dead:
    musket.fire_upwards()
  else:
    _fuse_shot_requested = true


func _on_musket_fired(hit: Dictionary) -> void:
  var enemy := hit.get('collider') as Enemy
  if enemy:
    enemy.take_shot()


func take_bite() -> void:
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
  _update_equipment()
  flip.scale *= 0.5
  aim_line.hide()
  set_process(false)
  set_physics_process(false)
  set_process_input(false)
  set_process_unhandled_input(false)
  died.emit()


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
  ramrod_drag_changed.emit(dragging)
  if not dragging:
    musket.cancel_ramrod()


func _dash() -> void:
  if (
    not _cooldown_timer.is_stopped() or not _dash_timer.is_stopped()
    or not _recovery_timer.is_stopped()
  ):
    return

  var direction := Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
  _dash_direction = _last_direction if direction.is_zero_approx() else direction.normalized()
  _dash_timer.start()
  _cooldown_timer.start()


func _interact() -> void:
  _set_dragging_ramrod(false)
  if not musket.is_owned and _within_reach(musket):
    _attach(musket, musket_back_slot)
    musket.equip()
  elif lantern.is_carried:
    lantern.reparent(_item_parent)
    lantern.global_transform = Transform3D(Basis.IDENTITY, drop_slot.global_position)
    lantern.set_carried(false)
  elif not musket.is_lit and _within_reach(lantern):
    _attach(lantern, lantern_slot)
    lantern.set_carried(true)
  _update_equipment()


func _within_reach(item: Node3D) -> bool:
  return global_position.distance_squared_to(item.global_position) <= pickup_radius * pickup_radius


func _attach(item: Node3D, slot: Marker3D) -> void:
  item.reparent(slot, false)
  item.transform = Transform3D.IDENTITY


func _update_equipment() -> void:
  var aiming := _aiming_requested()
  musket.set_aiming(aiming)
  if not musket.is_owned:
    return
  var slot := musket_aim_slot if aiming else musket_back_slot
  if musket.is_lit and not aiming:
    slot = musket_front_slot
  if musket.get_parent() != slot:
    _attach(musket, slot)
  if aiming:
    var camera := get_viewport().get_camera_3d()
    var origin := camera.unproject_position(musket.global_position)
    musket.aim(get_viewport().get_mouse_position() - origin)


func _aiming_requested() -> bool:
  return (
    not is_dead and musket.is_owned and not lantern.is_carried and not _dragging_ramrod
    and Input.is_action_pressed('aim_musket')
  )


func _get_aim_target(mouse: Vector2) -> Vector3:
  var camera := get_viewport().get_camera_3d()
  var origin := camera.project_ray_origin(mouse)
  var direction := camera.project_ray_normal(mouse)
  var target := global_position
  var point: Variant = Plane(Vector3.UP, global_position.y + aim_height).intersects_ray(origin, direction)
  if point != null:
    target = point
    target.y = global_position.y
  return global_position + (target - global_position).limit_length(musket.shot_range)


func _update_aim_line(target: Vector3) -> void:
  var direction := global_position.direction_to(target)
  var length := global_position.distance_to(target)
  if is_zero_approx(length):
    aim_line.hide()
    return
  aim_line.global_position = (global_position + target) * 0.5 + Vector3.UP * 0.025
  aim_line.global_basis = Basis(direction, Vector3.UP.cross(direction), Vector3.UP).scaled_local(
    Vector3(length, 0.025, 1.0)
  )


func _physics_process(_delta: float) -> void:
  var direction := Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
  if not direction.is_zero_approx():
    _last_direction = direction.normalized()

  if not _dash_timer.is_stopped():
    velocity = Vector3(_dash_direction.x, 0.0, _dash_direction.y) * dash_speed
  elif not _recovery_timer.is_stopped():
    velocity = Vector3.ZERO
  else:
    velocity = Vector3(direction.x, 0.0, direction.y) * speed

  move_and_slide()
  _update_equipment()
  aim_line.visible = musket.is_aiming
  var target := global_position
  if musket.is_aiming:
    target = _get_aim_target(get_viewport().get_mouse_position())
    _update_aim_line(target)
  if _shot_requested or _fuse_shot_requested:
    _shot_requested = false
    if musket.is_aiming:
      musket.fire(global_position, target, get_rid())
    if _fuse_shot_requested and musket.is_lit:
      musket.fire_upwards()
    _fuse_shot_requested = false
    _update_equipment()


func _on_dash_timer_timeout() -> void:
  _recovery_timer.start()
