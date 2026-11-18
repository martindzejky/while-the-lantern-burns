extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  var world := Node3D.new()
  root.add_child(world)
  var lantern := preload('res://objects/lantern.tscn').instantiate() as Lantern
  var musket := preload('res://objects/musket.tscn').instantiate() as Musket
  var player := preload('res://objects/player.tscn').instantiate() as Player
  player.lantern = lantern
  player.musket = musket
  for object: Node in [lantern, musket, player]:
    world.add_child(object)
  var camera := preload('res://objects/camera_controller.tscn').instantiate() as CameraController
  camera.target = player
  world.add_child(camera)
  var screen := preload('res://ui/victory_screen.tscn').instantiate() as VictoryScreen
  world.add_child(screen)

  musket.equip()
  musket.reload_state = Musket.ReloadState.LOADED
  musket.ignite()
  musket.set_aiming(true)
  _expect(musket.pull_trigger(), 'setup includes a pending shot')
  player.rig.set_frozen(true)
  world.process_mode = Node.PROCESS_MODE_DISABLED
  player.begin_escape()
  var camera_position := camera.global_position
  var start := player.global_position
  _expect(player.shape.disabled, 'walkout disables the player collider')
  _expect(player.collision_layer == 0 and player.collision_mask == 0, 'walkout cannot collide or be detected')
  _expect(not player.is_processing_input() and not player.is_processing_unhandled_input(), 'walkout ignores interaction input')
  player.take_bite()
  _expect(not player.is_dead, 'walkout is safe from damage')

  Input.action_press('move_right')
  Input.action_press('move_down')
  Input.action_press('aim_musket')
  await create_timer(0.7).timeout
  Input.action_release('move_right')
  Input.action_release('move_down')
  Input.action_release('aim_musket')
  _expect(player.global_position.z < start.z - 1.5, 'walkout moves north while the cave is frozen')
  _expect(is_equal_approx(player.global_position.x, start.x), 'held movement does not steer the walkout')
  _expect(is_equal_approx(player.global_position.y, start.y), 'walkout stays at floor height')
  _expect(camera.global_position.is_equal_approx(camera_position), 'camera stays behind')
  _expect(not musket.is_aiming and musket.reload_state == Musket.ReloadState.LOADED, 'pending shot stays unfired during walkout')

  screen.open()
  _expect(screen.menu_button.disabled, 'menu cannot interrupt the opening fade')
  await create_timer(1.0).timeout
  _expect(screen.background.color.a > 0.0 and screen.background.color.a < 1.0, 'daylight fades in gradually')
  _expect(is_zero_approx(screen.title.modulate.a), 'title waits until the background is opaque')
  await create_timer(2.7).timeout
  _expect(is_equal_approx(screen.background.color.a, 1.0), 'ending fully covers the world')
  _expect(is_equal_approx(screen.title.modulate.a, 1.0), 'ending title becomes visible')
  _expect(not screen.menu_button.disabled and screen.menu_button.has_focus(), 'menu becomes usable after the reveal')
  player.finish_escape()
  start = player.global_position
  await create_timer(0.15).timeout
  _expect(player.global_position.is_equal_approx(start), 'walkout stops behind the ending screen')
  world.queue_free()
  await process_frame
  for audio: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio as AudioStreamPlayer).stop()
    (audio as AudioStreamPlayer).stream = null
  await create_timer(0.1).timeout
  print('Ending tests: %d checks, %d failures' % [_checks, _failures])
  quit(1 if _failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error('FAILED: ' + message)
