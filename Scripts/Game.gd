extends Node2D

var UI #do wywalenia
var menu #pewnie też
var map
var last_room

var last_enemy = -1
var is_menu = false

onready var entities = $Entities
onready var effects = $Effects

var entity_list = {}
var special_entity_list = {}

func _process(delta):
	return ##do wywalenia to wszystko (może oprócz mapy)
	if Com.key_press("MAP"): #nie tej mapy
		var map = Com.player.get_node("Camera/UI/Map")
		map.visible = !map.visible
	
	var room = [map.map_x + int(Com.player.position.x)/1920, map.map_y + int(Com.player.position.y)/1080] #przenieść na server
	if room != last_room:
		UI.get_node("Map").set_room(room)
		last_room = room
		if !Com.player.chr.map.has(room):
			Com.player.chr.map.append(room)
			Network.send_data(["DISCOVER", room[0], room[1]]) #nie powinno wysyłać na samym początku

func load_map(id):
	map = Res.maps[id].instance()
	add_child(map)

func change_map(id):
	if map:
		map.queue_free()
		for entity in entities.get_children():
			entity.queue_free()
	
	load_map(id)

func add_main_player(player):
	player.connect("initiated", self, "start")
	add_child(player)
	player.connect("reg_mp", player.get_node("PlayerCamera/UI"), "reg_mp")
	player.connect("damaged", player.get_node("PlayerCamera/UI"), "player_damaged")
	UI = player.get_node("PlayerCamera/UI") #też \/
	menu = UI.get_node("PlayerMenu") #niepotrzebne

func damage_number(group, id, damage):
	var node
#	if group == "p":
#		for player in players.get_children():
#			if player.id == id:
#				node = player
#				break
#	elif group == "e":
#		node = enemies.get_child(id)
	
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

func got_soul(soul): ##do HUDu
	print(soul)

func get_enemy_number():
	last_enemy += 1
	return last_enemy

func add_entity(type, id):
	var node = load(str("res://Nodes/", Data.NODES[type], ".tscn")).instance()
	node.set_meta("valid", true)
	node.set_meta("id", id)
	
	entity_list[id] = node
	entities.add_child(node)
	if node.has_method("on_client_create"):
		node.on_client_create()
	else:
		node.visible = false
		node.set_process(false)
		node.set_physics_process(false)

func register_special_entity(entity):
	special_entity_list[entity.get_meta("id")] = entity

func register_entity(node, id):
	entity_list[id] = node

func remove_entity(id):
	var entity = entity_list.get(id)
	if entity:
		entity_list.erase(id)
		entity.queue_free()

func get_entity(id):
	return entity_list.get(id)

func get_special_entity(id):
	return special_entity_list.get(id)

func start(): ##:/
	Com.player.get_node("PlayerCamera/Fade/ColorRect").color.a = 0