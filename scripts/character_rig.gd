class_name CharacterRig
extends Node3D

enum EquipmentPose { IDLE, LANTERN, MUSKET_READY, MUSKET_AIM }

@export var animation: AnimationPlayer
@export var animation_tree: AnimationTree
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


func _ready() -> void:
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


func set_moving(moving: bool) -> void:
  _moving = moving


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
  animation_tree.set('parameters/life/transition_request', 'dead')
