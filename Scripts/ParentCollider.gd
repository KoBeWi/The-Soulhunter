extends Area2D

func _ready():
	connect("body_entered", get_parent(), "_body_enter")
	if get_parent().has_method("_body_exit"):
		connect("body_exited", get_parent(), "_body_exit")