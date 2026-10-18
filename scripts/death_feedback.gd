extends CanvasLayer

@export var player: Player
@export var overlay: ColorRect
@export var flash: ColorRect
@export var message: Label
@export var death_fade_duration: float = 0.2

var _material: ShaderMaterial
var _death_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
  _material = overlay.material as ShaderMaterial
  player.darkness_progress_changed.connect(_on_darkness_progress_changed)
  player.died.connect(_on_player_died)
  _on_darkness_progress_changed(player.darkness_progress)
  if player.is_dead:
    _on_player_died()


func _on_darkness_progress_changed(progress: float) -> void:
  _material.set_shader_parameter('darkness_progress', progress)


func _on_player_died() -> void:
  if _flash_tween:
    _flash_tween.kill()
  flash.modulate.a = 0.0
  _flash_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _flash_tween.tween_property(flash, 'modulate:a', 0.7, 0.025)
  _flash_tween.tween_property(flash, 'modulate:a', 0.0, 0.14)
  message.show()
  message.modulate.a = 0.0
  if _death_tween:
    _death_tween.kill()
  _death_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _death_tween.tween_method(_set_death_progress, 0.0, 1.0, death_fade_duration)
  _death_tween.parallel().tween_property(message, 'modulate:a', 1.0, death_fade_duration)


func _set_death_progress(progress: float) -> void:
  _material.set_shader_parameter('death_progress', progress)
