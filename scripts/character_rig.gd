class_name CharacterRig
extends Node3D

enum EquipmentPose { IDLE, LANTERN, MUSKET_READY, MUSKET_AIM }

@export var animation: AnimationPlayer
@export var animation_tree: AnimationTree
@export var skeleton: Skeleton3D
@export var flip: Node3D
@export var head: Sprite3D
@export var torso: Sprite3D
@export var head_front_texture: Texture2D
@export var head_back_texture: Texture2D
@export var torso_front_texture: Texture2D
@export var torso_back_texture: Texture2D
@export var left_hand_slot: Marker3D
@export var right_hand_slot: Marker3D
@export var back_slot: Marker3D
@export var pose_blend_duration: float = 0.18
@export var musket_angle: float = 1.0

var _equipment_pose: EquipmentPose = EquipmentPose.IDLE
var _moving: bool = false
var _movement_blend: float = 0.0
var _upper_body_blend: float = 0.0
var _dead: bool = false
var _facing_left: bool = false
var _facing_back: bool = false
var _aim_angle: float = 0.0
var _aim_blend: float = 0.0
var _aim_origin_bone: int


func _ready() -> void:
  _aim_origin_bone = skeleton.find_bone('shoulder_left')
  animation_tree.active = true
  animation_tree.set('parameters/life/transition_request', 'alive')
  animation_tree.set('parameters/equipment/transition_request', 'neutral')
  animation_tree.advance(0.0)


func _process(delta: float) -> void:
  if _dead:
    return
  var step := delta / pose_blend_duration
  _movement_blend = move_toward(_movement_blend, 1.0 if _moving else 0.0, step)
  _upper_body_blend = move_toward(
    _upper_body_blend, 0.0 if _equipment_pose == EquipmentPose.IDLE else 1.0, step
  )
  animation_tree.set('parameters/locomotion/blend_amount', _movement_blend)
  animation_tree.set('parameters/upper_body/blend_amount', _upper_body_blend)
  _aim_blend = move_toward(_aim_blend, 1.0 if _equipment_pose == EquipmentPose.MUSKET_AIM else 0.0, step)
  animation_tree.set('parameters/aim/add_amount', _aim_angle / (PI * 0.5) * _aim_blend)


func set_moving(moving: bool) -> void:
  _moving = moving


func set_facing(direction: Vector2) -> void:
  if _dead:
    return
  if not is_zero_approx(direction.x) and _facing_left != (direction.x < 0.0):
    _facing_left = direction.x < 0.0
    flip.scale = Vector3(-1.0 if _facing_left else 1.0, 1.0, 1.0)
  if is_zero_approx(direction.y) or _facing_back == (direction.y < 0.0):
    return
  _facing_back = direction.y < 0.0
  head.texture = head_back_texture if _facing_back else head_front_texture
  torso.texture = torso_back_texture if _facing_back else torso_front_texture
  (head.material_override as ShaderMaterial).set_shader_parameter('sprite_texture', head.texture)
  (torso.material_override as ShaderMaterial).set_shader_parameter('sprite_texture', torso.texture)
  var depth_bones: Array[StringName] = [
    &'shoulder_left', &'shoulder_right', &'hand_left', &'hand_right', &'back'
  ]
  for bone: StringName in depth_bones:
    var index := skeleton.find_bone(bone)
    var depth := skeleton.get_bone_rest(index).origin.z
    _set_bone_depth(index, -depth if _facing_back else depth)
  var left := skeleton.find_bone('leg_left')
  var right := skeleton.find_bone('leg_right')
  var left_depth := skeleton.get_bone_rest(left).origin.z
  var right_depth := skeleton.get_bone_rest(right).origin.z
  _set_bone_depth(left, right_depth if _facing_back else left_depth)
  _set_bone_depth(right, left_depth if _facing_back else right_depth)


func _set_bone_depth(bone: int, depth: float) -> void:
  var bone_position := skeleton.get_bone_pose_position(bone)
  bone_position.z = depth
  skeleton.set_bone_pose_position(bone, bone_position)


func is_facing_left() -> bool:
  return _facing_left


func get_aim_origin() -> Vector3:
  return skeleton.to_global(skeleton.get_bone_global_pose(_aim_origin_bone).origin)


func set_aim_direction(direction: Vector2) -> void:
  if _dead or direction.is_zero_approx():
    return
  _aim_angle = atan2(-direction.y, absf(direction.x))


func set_equipment_pose(pose: EquipmentPose) -> void:
  if _dead or _equipment_pose == pose:
    return
  _equipment_pose = pose
  var state: String = ['neutral', 'lantern', 'musket', 'aiming'][pose]
  animation_tree.set('parameters/equipment/transition_request', state)


func get_left_hand_slot() -> Marker3D:
  return left_hand_slot


func get_right_hand_slot() -> Marker3D:
  return right_hand_slot


func get_back_slot() -> Marker3D:
  return back_slot


func get_musket_angle() -> float:
  return musket_angle


func show_death() -> void:
  if _dead:
    return
  _dead = true
  var death := animation.get_animation('death').duplicate() as Animation
  for track in death.get_track_count():
    var path := death.track_get_path(track)
    var type := death.track_get_type(track)
    var current: Variant
    if path.get_subname_count() > 0 and type != Animation.TYPE_VALUE:
      var bone := skeleton.find_bone(path.get_subname(0))
      match type:
        Animation.TYPE_POSITION_3D:
          current = skeleton.get_bone_pose_position(bone)
        Animation.TYPE_ROTATION_3D:
          current = skeleton.get_bone_pose_rotation(bone)
        Animation.TYPE_SCALE_3D:
          current = skeleton.get_bone_pose_scale(bone)
      death.track_insert_key(track, death.length, death.track_get_key_value(track, 0))
    else:
      match type:
        Animation.TYPE_POSITION_3D:
          current = position
        Animation.TYPE_ROTATION_3D:
          current = quaternion
        Animation.TYPE_VALUE:
          current = musket_angle
    death.track_set_key_value(track, 0, current)
  animation.get_animation_library('').add_animation('death', death)
  animation_tree.set('parameters/life/transition_request', 'dead')
