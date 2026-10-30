extends SceneTree

const OBJECTS: Array[PackedScene] = [
  preload('res://objects/player.tscn'),
  preload('res://objects/lantern.tscn'),
  preload('res://objects/musket.tscn'),
  preload('res://objects/enemy.tscn'),
]

class ProcessProbe extends Node:
  var frames: int = 0

  func _process(_delta: float) -> void:
    frames += 1

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  var camera := Camera3D.new()
  camera.rotation_degrees.x = -40.0
  root.add_child(camera)
  camera.make_current()
  var world := Node3D.new()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  root.add_child(world)
  var player := OBJECTS[0].instantiate() as Player
  var lantern := OBJECTS[1].instantiate() as Lantern
  var musket := OBJECTS[2].instantiate() as Musket
  var enemy := OBJECTS[3].instantiate() as Enemy
  player.lantern = lantern
  player.musket = musket
  enemy.target = player
  for object: Node in [lantern, musket, player, enemy]:
    world.add_child(object)
    var facing := object.get_node('camera_facing') as CameraFacing
    _expect(facing.process_mode == Node.PROCESS_MODE_ALWAYS, '%s facing always processes' % object.name)
    _expect(facing.target == object.get_node('visuals'), '%s targets its visuals' % object.name)
    _expect(facing.get_child_count() == 0, '%s facing cannot unpause descendants' % object.name)

  var facing := player.get_node('camera_facing') as CameraFacing
  var visuals: Node3D = facing.target
  var probe := ProcessProbe.new()
  visuals.add_child(probe)
  var timer := Timer.new()
  timer.wait_time = 10.0
  timer.autostart = true
  world.add_child(timer)
  await process_frame
  await process_frame
  _expect(visuals.global_basis.is_equal_approx(camera.global_basis), 'faces camera during disabled transition')
  _expect(probe.frames == 0 and is_equal_approx(timer.time_left, 10.0), 'visual descendants and timers stay frozen')

  paused = true
  camera.rotation_degrees.x = -25.0
  await process_frame
  await process_frame
  _expect(visuals.global_basis.is_equal_approx(camera.global_basis), 'follows camera changes while tree is paused')
  _expect(probe.frames == 0 and is_equal_approx(timer.time_left, 10.0), 'paused animation and timers remain frozen')

  facing.enabled = false
  visuals.basis = Basis.IDENTITY
  await process_frame
  await process_frame
  _expect(visuals.basis.is_equal_approx(Basis.IDENTITY), 'held items preserve their attachment transform')
  paused = false

  var controller := preload('res://objects/camera_controller.tscn').instantiate() as CameraController
  controller.target = player
  world.add_child(controller)
  controller.set_level(Rect2(-1, -1, 2, 2), [])
  var focus := preload('res://objects/camera_focus.tscn').instantiate() as CameraFocus
  focus.position = Vector3(5, 0, -4)
  focus.inner_radius = 7.0
  world.add_child(focus)
  controller._on_focus_entered(focus, player)
  controller._process(1.0)
  _expect(controller.position.x > 1.0, 'reveal can frame beyond level follow bounds')
  _expect(controller.position.z < -1.0, 'reveal retains its depth near a level boundary')
  var screen_size: Vector2 = root.get_visible_rect().size
  var screen_position: Vector2 = controller.camera.unproject_position(player.global_position)
  _expect(Rect2(screen_size * 0.24, screen_size * 0.52).has_point(screen_position), 'boundary reveal keeps player safely framed')
  controller._on_focus_exited(focus, player)
  controller._process(2.0)
  _expect(controller.position.length() < 0.01, 'camera returns to bounded player follow after reveal')
  world.queue_free()
  camera.queue_free()
  await process_frame
  for audio: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio as AudioStreamPlayer).stop()
    (audio as AudioStreamPlayer).stream = null
  await create_timer(0.1).timeout
  print('Camera facing tests: %d checks, %d failures' % [_checks, _failures])
  quit(1 if _failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error('FAILED: ' + message)
