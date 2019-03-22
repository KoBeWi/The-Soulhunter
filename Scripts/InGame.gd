extends Node2D

var UI
var chat
var menu
var map
var enemies
var last_room

var last_enemy = -1
var is_menu = false

onready var effects = $Effects

func _process(delta):
	if Com.server:
		for player in $Players.get_children():
			if !player.initiated or player.changeroomed: continue
			
			if player.position.x >= map.width * 1920:
				player.changeroomed = true
				Network.send_data(["CHANGEROOM", map.mapid, player.id, "r", int(player.position.y) / 1080])
			elif player.position.x < 0:
				player.changeroomed = true
				Network.send_data(["CHANGEROOM", map.mapid, player.id, "l", int(player.position.y) / 1080])
	else:
		if Com.key_press("_ACCEPT") and chat.has_focus():
			if chat.text.left(1) == "/":
				chat.get_node("..").parse_command(chat.text)
			else:
				chat.get_node("..").add_message(Com.player.uname, chat.text)
				var data = chat.get_node("..").get_data()
				Network.send_data(["CHAT"] + data + [chat.text])
			chat.text = ""
			chat.placeholder_text = "Press T to chat"
			chat.release_focus()
		elif Com.key_press("_CANCEL") and chat.has_focus():
			chat.text = ""
			chat.placeholder_text = "Press T to chat"
			chat.release_focus()
		elif Com.key_press("MENU") and !is_menu:
			menu.show()
			menu.set_process(true)
			Network.send_data(["GETSTATS", "2"])
			Network.send_data(["GETINVENTORY"])
			Network.send_data(["GETEQUIPMENT"])
			is_menu = true
		elif Com.key_press("MENU"):
			menu.visible = false
			menu.set_process(false)
			is_menu = false
			
		if Com.key_press("MAP"):
			var map = Com.player.get_node("Camera/UI/Map")
			map.visible = !map.visible
			
		if Com.key_press("CHAT"):
			chat.placeholder_text = ""
			chat.grab_focus()
		elif Com.key_press("_COMMAND"):
			chat.placeholder_text = ""
			chat.text = "/"
			chat.caret_position = 1
			chat.grab_focus()
		
		return
		var room = [map.map_x 	+ int(Com.player.position.x)/1920, map.map_y + int(Com.player.position.y)/1080] #przenieść na server
		if room != last_room:
			UI.get_node("Map").set_room(room)
			last_room = room
			if !Com.player.chr.map.has(room):
				Com.player.chr.map.append(room)
#				Network.send_data(["DISCOVER", room[0], room[1]]) #nie powinno wysyłać na samym początku

func load_map(id):
	map = Res.maps[id].instance()
	add_child(map)
	enemies = map.get_node("Enemies")
	update_camera()

func update_camera():
	if Com.player:
		var camera = Com.player.camera
		camera.limit_right = map.width * 1920
		camera.limit_bottom = map.height * 1080

func change_map(id):
	map.queue_free()
	for player in $Players.get_children():
		if player != Com.player:
			Com.controls.remove_player(player)
			player.queue_free()
			
	load_map(id)

func add_main_player(player):
	$Players.add_child(player)
	UI = player.get_node("PlayerCamera/UI")
	menu = UI.get_node("PlayerMenu")
	chat = UI.get_node("Chat/Input")

func damage_number(group, id, damage):
	var node
	if group == "p":
		for player in $Players.get_children():
			if player.id == id:
				node = player
				break
	elif group == "e":
		node = enemies.get_child(id)
	
	if !node:
		print("WARNING: Damage number for non-existing object")
		return
	node.damage(damage)
	
	var label = load("res://Nodes/DamageNumber.tscn").instance()
	label.get_node("Number").set_text(str(damage))
	
	if node.has_node("NumberPoint"):
		label.position = node.get_node("NumberPoint").position
	
	label.global_position = node.global_position
	effects.add_child(label)

func got_soul(soul):
	print(soul)

func update_stats(stats):
	if stats.has("level"):
		Com.player.chr.level = stats["level"]
	if stats.has("experience"):
		Com.player.chr.experience = stats["experience"]
	if stats.has("maxhp"):
		Com.player.chr.max_hp = stats["maxhp"]
	if stats.has("hp"):
		Com.player.chr.hp = stats["hp"]
	if stats.has("maxmp"):
		Com.player.chr.max_mp = stats["maxmp"]
	if stats.has("mp"):
		Com.player.chr.mp = stats["mp"]
	if stats.has("attack"):
		Com.player.chr.attack = stats["attack"]
	if stats.has("defense"):
		Com.player.chr.defense = stats["defense"]
	
	menu.update_status()

func update_inventory(items):
	Com.player.chr.update_inventory(items)
	menu.update_inventory()

func update_equipment(items):
	Com.player.chr.update_equipment(items)
	menu.update_equipment()

func get_player(id):
	for player in $Players.get_children():
		if player.id == id:
			return player

func get_enemy(id):
	for enemy in enemies.get_children():
		if enemy.id == id:
			return enemy

func get_enemy_number():
	last_enemy += 1
	return last_enemy

func start():
	Com.player.initiated = true
	Com.player.get_node("PlayerCamera/Fade/ColorRect").color.a = 0