extends Node2D

var time = 45

func _physics_process(delta):
	translate(Vector2(0, -time/15))
	time -= 1
	
	if time == 0:
		queue_free()