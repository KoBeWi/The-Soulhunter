extends Node

func initialize(scene):
	scene.load_map(ProjectSettings.get("CurrentMap"))
	var entrance = ProjectSettings.get("Entrance")
	var start_pos = Vector2(0, 0)
	var player = load("res://Nodes/Player.tscn").instance()
	
	if entrance[0] == 5:
		start_pos = scene.get_node("Map/Map/SavePoint/PlayerSpot").get_global_pos()
	elif entrance[0] == 0:
		start_pos = Vector2(entrance[1] * 1920, 0)
	elif entrance[0] == 1:
		start_pos = Vector2(scene.map.width * 1920 - 1, entrance[1] * 1080 + 540)
		player.get_node("Sprite").set_flip_h(true)
	elif entrance[0] == 2:
		start_pos = Vector2(entrance[1] * 1920, scene.map.height * 1080 - 1)
	elif entrance[0] == 3:
		start_pos = Vector2(0, entrance[1] * 1080 + 540)
	ProjectSettings.set("Player", player)
	
	var camera = load("res://Nodes/Camera.tscn").instance()
	camera.make_current()
	camera.set_limit(2, scene.get_node("Map/Map").width * 1920)
	camera.set_limit(3, scene.get_node("Map/Map").height * 1080)
	player.add_child(camera)
	
	scene.get_node("Players").add_child(player)
	player.set_pos_and_broadcast(Vector2(start_pos.x, start_pos.y - 49))
	player.initialize(ProjectSettings.get("PlayerName"))
	ProjectSettings.set("Entrance", null)