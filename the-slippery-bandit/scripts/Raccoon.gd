extends Node3D

@onready var animations = $AnimationPlayer


func play_animation(anim_name: String):
	if animations.has_animation(anim_name) and (animations.current_animation != anim_name):
		animations.play(anim_name)

func stop_animations():
	animations.stop()
