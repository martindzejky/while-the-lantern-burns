extends CanvasLayer

@export var musket: Musket
@export var player: Player


func _ready() -> void:
  player.set_darkness_enabled(false)
  await musket.warm_up_effects()
  if is_instance_valid(self):
    player.set_darkness_enabled(true)
    queue_free()
