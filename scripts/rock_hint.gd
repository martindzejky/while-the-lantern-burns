extends Node3D

@export var text: HintLabel
@export var rocks: Array[CrumblingRock] = []


func _ready() -> void:
  for rock: CrumblingRock in rocks:
    rock.shot.connect(_on_rock_shot)
  text.set_message('Shoot the rocks\nto clear a path')


func _on_rock_shot() -> void:
  text.set_message('')
