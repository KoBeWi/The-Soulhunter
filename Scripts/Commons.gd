extends Node

const ENEMY_NAMES = ["Skeleton"]

var game
var server
var player

var keys = {}
var pressed_keys = {}
var controls

func _ready():
	controls = load("res://Scripts/Controls.gd").new()
	add_child(controls)

func _process(delta):
	for key in keys.keys():
		pressed_keys[key] = true

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