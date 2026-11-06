extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  var world := Node3D.new()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  root.add_child(world)
  var player := preload('res://objects/player.tscn').instantiate() as Player
  var lantern := preload('res://objects/lantern.tscn').instantiate() as Lantern
  var musket := preload('res://objects/musket.tscn').instantiate() as Musket
  player.lantern = lantern
  player.musket = musket
  for object: Node in [lantern, musket, player]:
    world.add_child(object)
  var gameplay := CaveGameplay.new()
  gameplay.player = player
  gameplay._active = true
  var enemies: Array[Enemy] = []
  for index: int in range(2):
    var enemy := preload('res://objects/enemy.tscn').instantiate() as Enemy
    enemy.target = player
    enemy.position = Vector3(index * 10.0, 0.0, 0.0)
    enemy.bite_started.connect(gameplay._on_bite_started)
    enemy.bite_windup_finished.connect(gameplay._on_bite_finished)
    enemy.bite_finished.connect(gameplay._on_bite_finished)
    enemy.tree_exiting.connect(gameplay._on_bite_finished.bind(enemy))
    world.add_child(enemy)
    enemies.append(enemy)
  var enemy := enemies[0]
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'walking is 20% slower')
  _expect(is_equal_approx(enemy.speed, 0.95 * 1.2), 'chasing is 20% faster')
  enemy.bite()
  _expect(is_equal_approx(enemy._lunge_start_time / enemy.animation.get_playing_speed(), 0.8 / 1.2), 'windup completes 20% faster')
  _expect(is_equal_approx(player.get_movement_speed(false), 2.24), 'windup slows walking another 30%')
  _expect(is_equal_approx(player.get_movement_speed(true), 1.12), 'windup composes with aiming slowdown')
  enemies[1].bite()
  _expect(is_equal_approx(player.get_movement_speed(false), 2.24), 'overlapping windups do not stack')
  enemy._begin_lunge()
  _expect(is_equal_approx(player.get_movement_speed(false), 2.24), 'other windup keeps slowdown after first lunge')
  enemies[1].take_shot()
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'killing final windup restores movement')
  enemy._finish_bite()
  enemy.bite()
  enemy._begin_lunge()
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'lunge start releases slowdown before recovery')
  enemy._finish_bite()
  enemy.bite()
  gameplay.set_active(false)
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'transition clears slowdown')
  enemy._finish_bite()
  gameplay._active = true
  enemy.bite()
  gameplay._on_player_died()
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'death clears slowdown')
  enemy._finish_bite()
  gameplay._active = true
  enemy.bite()
  enemy.queue_free()
  await process_frame
  _expect(is_equal_approx(player.get_movement_speed(false), 3.2), 'removing winding monster clears slowdown')

  # the new radius catches a close sidestep that escaped the old 1.1 radius.
  enemy = preload('res://objects/enemy.tscn').instantiate() as Enemy
  enemy.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
  enemy.target = player
  world.add_child(enemy)
  player.position = Vector3(2.3, 0.0, 1.2)
  enemy.bite()
  var committed_direction := enemy._bite_direction
  player.position = Vector3(2.3, 0.0, 1.5)
  enemy._begin_lunge()
  _expect(enemy._bite_direction.is_equal_approx(committed_direction), 'lunge keeps direction committed at windup start')
  enemy._bite_direction = Vector3.RIGHT
  await physics_frame
  await process_frame
  enemy._update_lunge(0.24)
  _expect(not player.is_dead, 'a wider lateral dodge survives the lunge')
  enemy._finish_bite()
  enemy.position = Vector3.ZERO
  player.position = Vector3(2.3, 0.0, 1.2)
  enemy.bite()
  enemy._bite_direction = Vector3.RIGHT
  enemy._begin_lunge()
  enemy._update_lunge(0.24)
  _expect(player.is_dead, 'swept lunge catches a close lateral dodge')
  _expect(enemy.position.x > 2.0, 'lunge travels farther than the old distance')
  _expect(is_equal_approx(enemy.lunge_speed, 10.0), 'lunge moves faster')
  gameplay.free()
  world.queue_free()
  await process_frame
  for audio: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio as AudioStreamPlayer).stop()
    (audio as AudioStreamPlayer).stream = null
  await create_timer(0.1).timeout
  print('Monster threat tests: %d checks, %d failures' % [_checks, _failures])
  quit(1 if _failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error('FAILED: ' + message)
