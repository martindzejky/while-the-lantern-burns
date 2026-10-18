class_name UIAudio
extends Node

@export var hover_audio: AudioStreamPlayer
@export var click_audio: AudioStreamPlayer


func play_hover() -> void:
  hover_audio.play()


func play_click() -> void:
  click_audio.play()
