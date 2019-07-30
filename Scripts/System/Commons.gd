extends Node

onready var controls : Controls = $Controls

var version = 2

var game
var is_server = false
var player

var keys = {}
var pressed_keys = {}

signal enemy_attacked(enemy, damage)

func _process(delta):
	for key in keys.keys():
		pressed_keys[key] = true

##niepotrzebne??
func press_key(key):
	keys[key] = true

func release_key(key):
	keys.erase(key)
	if pressed_keys.has(key):
		pressed_keys.erase(key)

func key_press(key):
	return (keys.has(key) and !pressed_keys.has(key))

func key_hold(key):
	return keys.has(key)

func register_node(node, type, client_only = false):
	if is_server:
		node.set_meta("room", node.find_parent("InGame").get_parent())
		node.get_meta("room").RegisterNode(node, Data.NODES.find(type), client_only)
		if client_only: node.queue_free()
		return client_only
	elif !node.has_meta("valid"):
		node.queue_free()
		return true

func register_special_node(node):
	if is_server:
		node.set_meta("room", node.find_parent("InGame").get_parent())
		node.get_meta("room").RegisterSpecialNode(node)
		node.set_meta("id", str(node.get_meta("room").get("mapId"), "_", node.get_position_in_parent()))
	else:
		node.set_meta("id", str(Com.game.map.mapid, "_", node.get_position_in_parent()))
		Com.game.register_special_entity(node)

func dispose_node(node):
	if is_server:
		node.get_meta("room").DisposeNode(node.get_meta("id"))
		node.queue_free()
	elif !node.has_meta("valid"):
		node.queue_free()

func time_greater(server, client):
	if server > client:
		return true
	elif server < 96 and client > 160:
		return true

func exp_for_level(level):
	return level * 10
	
func total_exp_for_level(level):
	return level * (level + 1) * 5