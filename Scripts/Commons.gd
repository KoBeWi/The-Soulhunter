extends Node

const ENEMY_NAMES = ["Skeleton"] ##enum?

onready var controls = $Controls

var game
var is_server = false
var player

var keys = {}
var pressed_keys = {}

func _process(delta):
	for key in keys.keys():
		pressed_keys[key] = true

##niepotrzebne
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

func register_node(node, type):
	if is_server:
		node.set_meta("room", node.find_parent("InGame").get_parent())
		node.get_meta("room").call("RegisterNode", node, Data.NODES.find(type))
	elif !node.has_meta("valid"):
		node.queue_free()
		return true