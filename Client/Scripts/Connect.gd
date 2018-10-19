extends Node

func _process(delta):
	if get_node("/root/Network").connected:
		get_tree().change_scene("Scenes/Login.tscn")