extends Area2D

func _ready():
	connect("body_entered", get_node(".."), "_body_enter")
	if get_node("..").has_method("_body_exit"):
		connect("body_exited", get_node(".."), "_body_exit")