@tool
extends EditorPlugin

const RANDOM_ROCK: PackedScene = preload('res://objects/random_big_rock.tscn')

var _place_button: Button


func _enter_tree() -> void:
  _place_button = Button.new()
  _place_button.text = 'Place Random Rock'
  _place_button.tooltip_text = 'Place a rock on the cave floor at the center of the 3D view.'
  _place_button.pressed.connect(_place_rock)
  add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _place_button)


func _exit_tree() -> void:
  remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _place_button)
  _place_button.queue_free()


func _place_rock() -> void:
  var level := EditorInterface.get_edited_scene_root() as Node3D
  var ground := level.get_node_or_null('ground') as CSGPolygon3D if level != null else null
  if ground == null:
    EditorInterface.get_editor_toaster().push_toast('Open a cave scene to place rocks.')
    return

  var viewport: SubViewport = EditorInterface.get_editor_viewport_3d()
  var camera: Camera3D = viewport.get_camera_3d()
  var center: Vector2 = viewport.get_visible_rect().get_center()
  var floor_plane := Plane(Vector3.UP, ground.global_position.y)
  var hit: Variant = floor_plane.intersects_ray(camera.project_ray_origin(center), camera.project_ray_normal(center))
  if hit == null:
    EditorInterface.get_editor_toaster().push_toast('Tilt the 3D view toward the cave floor.')
    return
  var floor_position: Vector3 = hit
  _add_rock(level, floor_position)


func _add_rock(level: Node3D, floor_position: Vector3) -> void:
  var rocks := level.get_node_or_null('rocks') as Node3D
  var create_container: bool = rocks == null
  if create_container:
    rocks = Node3D.new()
    rocks.name = 'rocks'

  var rock := RANDOM_ROCK.instantiate() as RandomBigRock
  rock.seed_value = randi()
  rock.position = level.to_local(floor_position) if create_container else rocks.to_local(floor_position)

  var history: EditorUndoRedoManager = get_undo_redo()
  history.create_action('Place Random Rock', UndoRedo.MERGE_DISABLE, level)
  if create_container:
    history.add_do_method(level, &'add_child', rocks, true)
    history.add_do_property(rocks, &'owner', level)
    history.add_do_reference(rocks)
  history.add_do_method(rocks, &'add_child', rock, true)
  history.add_do_property(rock, &'owner', level)
  history.add_do_reference(rock)
  history.add_undo_method(rocks, &'remove_child', rock)
  if create_container:
    history.add_undo_method(level, &'remove_child', rocks)
  history.commit_action()

  var selection: EditorSelection = EditorInterface.get_selection()
  selection.clear()
  selection.add_node(rock)
