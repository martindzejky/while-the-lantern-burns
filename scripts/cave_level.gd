class_name CaveLevel
extends Node3D

@export var entry: Marker3D
@export var lantern_spawn: Marker3D
@export var musket_spawn: Marker3D
# camera focus limits on the XZ plane.
@export var camera_bounds: Rect2
@export var enemies: Array[Enemy] = []
@export var focuses: Array[CameraFocus] = []
@export var lantern_focus: CameraFocus
@export var musket_focus: CameraFocus
@export var exit: Area3D
