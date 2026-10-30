class_name CameraFacing
extends Node

@export var target: Node3D

var enabled: bool = true


func _process(_delta: float) -> void:
  if not enabled:
    return
  var camera := get_viewport().get_camera_3d()
  if camera:
    target.global_basis = camera.global_basis
