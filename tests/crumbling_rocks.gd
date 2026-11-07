extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  var world := Node3D.new()
  root.add_child(world)
  current_scene = world
  var camera := Camera3D.new()
  world.add_child(camera)
  camera.make_current()
  var player := preload('res://objects/player.tscn').instantiate() as Player
  var lantern := preload('res://objects/lantern.tscn').instantiate() as Lantern
  var musket := preload('res://objects/musket.tscn').instantiate() as Musket
  player.lantern = lantern
  player.musket = musket
  musket.fired.connect(player._on_musket_fired)
  for object: Node in [lantern, musket, player]:
    object.process_mode = Node.PROCESS_MODE_DISABLED
    world.add_child(object)
  player.position = Vector3(-3.0, 0.0, 0.0)
  for index: int in range(1, 9):
    var scene := load('res://objects/big_rock_%02d.tscn' % index) as PackedScene
    var rock := scene.instantiate() as CrumblingRock
    var neighbor := scene.instantiate() as CrumblingRock
    neighbor.position = Vector3(0.0, 0.0, 5.0)
    world.add_child(rock)
    world.add_child(neighbor)
    var shared_material := neighbor.sprite.material_override
    var original_texture: Texture2D = rock.sprite.texture
    await physics_frame
    await physics_frame
    musket.is_aiming = true
    musket.reload_state = Musket.ReloadState.LOADED
    musket.is_lit = true
    var hit := musket.fire(player.position, rock.position, player.get_rid())
    _expect(hit.get('collider') == rock, 'variant %d is hit by musket ray' % index)
    _expect(rock.collision_layer == 0 and rock.collision_mask == 0, 'hit removes blocking collision immediately')
    var flash := rock.sprite.material_override as ShaderMaterial
    _expect(flash != shared_material and neighbor.sprite.material_override == shared_material, 'flash does not alter another rock')
    _expect(flash.shader == rock.flash_shader and flash.get_shader_parameter('rock_texture') == original_texture, 'white flash shader preserves the rock silhouette')
    rock.take_shot()
    await create_timer(0.25).timeout
    await process_frame
    _expect(not is_instance_valid(rock), 'rock disappears after brief flash')
    var dust_count: int = 0
    for child: Node in world.get_children():
      if child is CPUParticles3D and String(child.name).begins_with('rock_crumble'):
        dust_count += 1
    _expect(dust_count == 1, 'repeat hits produce only one crumble effect')
    var query := PhysicsRayQueryParameters3D.create(Vector3(-3.0, 0.1, 0.0), Vector3(3.0, 0.1, 0.0), 3, [player.get_rid()])
    _expect(world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), 'shots pass through destroyed rock')
    for child: Node in world.get_children():
      if child is CPUParticles3D:
        child.queue_free()
    neighbor.queue_free()
    await process_frame

  for index: int in range(1, 8):
    var scene := load('res://objects/small_rock_%02d.tscn' % index) as PackedScene
    var rock := scene.instantiate() as StaticBody3D
    _expect(not rock is CrumblingRock and (rock.get_node('shape') as CollisionShape3D).disabled, 'decorative small rock %d stays unchanged' % index)
    rock.free()

  var effect := preload('res://effects/rock_crumble.tscn').instantiate() as CPUParticles3D
  world.add_child(effect)
  var audio := effect.get_node('audio') as AudioStreamPlayer3D
  var sounds := audio.stream as AudioStreamRandomizer
  _expect(audio.playing and audio.bus == &'World SFX Heavy Reverb', 'crumble sound starts on world SFX bus')
  _expect(sounds.streams_count == 3, 'three crumble variants are configured')
  for index: int in range(sounds.streams_count):
    _expect(is_equal_approx(sounds.get_stream(index).get_length(), 2.0), 'sound variant lasts exactly two seconds')
  await create_timer(3.2).timeout
  _expect(not is_instance_valid(effect), 'dust and audio clean themselves up')
  world.queue_free()
  await process_frame
  for audio_player: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio_player as AudioStreamPlayer).stop()
    (audio_player as AudioStreamPlayer).stream = null
  await create_timer(0.1).timeout
  print('Crumbling rocks: %d checks, %d failures' % [_checks, _failures])
  quit(1 if _failures else 0)


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error(message)
