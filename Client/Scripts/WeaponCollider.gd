extends Area2D

func _ready():
	connect("body_entered", get_node("../../../../../../.."), "weapon_enter")
	connect("body_exited", get_node("../../../../../../.."), "weapon_exit")