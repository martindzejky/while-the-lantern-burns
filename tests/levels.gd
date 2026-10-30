extends SceneTree

const LEVELS: Array[PackedScene] = [
  preload('res://scenes/levels/discovery.tscn'),
  preload('res://scenes/levels/deep_cave.tscn'),
  preload('res://scenes/levels/escape.tscn'),
]

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
  _run.call_deferred()


func _run() -> void:
  await create_timer(0.1).timeout
  for scene: PackedScene in LEVELS:
    var level := scene.instantiate() as CaveLevel
    var floor := level.get_node('ground') as CSGPolygon3D
    var outline: PackedVector2Array = floor.polygon
    _expect(not Geometry2D.triangulate_polygon(outline).is_empty(), '%s floor triangulates' % level.name)
    _expect(_is_simple(outline), '%s floor has no crossed edges' % level.name)
    _expect(level.camera_bounds.has_area(), '%s has camera focus limits' % level.name)
    var landmarks: Array[Node3D] = [level.entry, level.lantern_spawn, level.musket_spawn, level.exit]
    for enemy: Enemy in level.enemies:
      landmarks.append(enemy)
    for landmark: Node3D in landmarks:
      _expect(_on_floor(floor, landmark.position), '%s/%s is on the floor' % [level.name, landmark.name])
    if level.name == 'discovery':
      _expect(level.focuses.size() == 2, 'discovery has both item reveals')
      _expect(level.focuses.has(level.lantern_focus), 'lantern reveal is registered')
      _expect(level.focuses.has(level.musket_focus), 'musket reveal is registered')
      _expect(level.lantern_focus.position.is_equal_approx(level.lantern_spawn.position), 'lantern reveal follows spawn')
      _expect(level.musket_focus.position.is_equal_approx(level.musket_spawn.position), 'musket reveal follows spawn')
      _expect(level.lantern_focus.position.distance_to(level.entry.position) > level.lantern_focus.outer_radius, 'entrance does not trigger lantern reveal')
      _expect(level.camera_bounds.grow(0.01).has_point(Vector2(level.entry.position.x, level.entry.position.z)), 'camera can center on entrance')
      for point: Vector3 in [Vector3(-27, 0, -10), Vector3(7, 0, -10), Vector3(7, 0, 0)]:
        _expect(_on_floor(floor, point), 'discovery bends are walkable: %s' % point)
      _expect(not _on_floor(floor, Vector3(-18, 0, 6)), 'entrance requires walking up before right')
      _expect(not _on_floor(floor, Vector3(14, 0, -8)), 'musket route requires the narrow descent')
    if level.name == 'deep_cave':
      _expect(level.focuses.size() == 1, 'deep cave has its first encounter reveal')
      _expect(level.focuses[0].position.is_equal_approx(level.enemies[0].position), 'first encounter reveal follows enemy spawn')
    if level.name == 'escape':
      _expect(not _on_floor(floor, Vector3(-3, 0, -15)), 'escape U bend has an open central gap')
    level.free()
  for audio: Node in root.find_children('*', 'AudioStreamPlayer', true, false):
    (audio as AudioStreamPlayer).stop()
    (audio as AudioStreamPlayer).stream = null
  print('Level tests: %d checks, %d failures' % [_checks, _failures])
  await create_timer(0.1).timeout
  quit(1 if _failures > 0 else 0)


func _on_floor(floor: CSGPolygon3D, position: Vector3) -> bool:
  # levels author their ground and landmarks as direct children of the root.
  var local := floor.transform.affine_inverse() * position
  return Geometry2D.is_point_in_polygon(Vector2(local.x, local.y), floor.polygon)


func _is_simple(outline: PackedVector2Array) -> bool:
  for index: int in range(outline.size()):
    var next: int = (index + 1) % outline.size()
    for other: int in range(index + 1, outline.size()):
      var other_next: int = (other + 1) % outline.size()
      if other == next or other_next == index:
        continue
      if Geometry2D.segment_intersects_segment(outline[index], outline[next], outline[other], outline[other_next]) != null:
        return false
  return true


func _expect(condition: bool, message: String) -> void:
  _checks += 1
  if not condition:
    _failures += 1
    push_error('FAILED: ' + message)
