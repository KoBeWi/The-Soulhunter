class_name Controls
extends Node

enum{ATTACK, JUMP, UP, RIGHT, DOWN, LEFT, ACCEPT, CANCEL, MAP, MENU, CHAT, COMMAND}

signal key_press
signal key_release

var players = {}
var controls = {}

func _ready():
	set_process(false)

func set_master(player):
	set_process(true)

func _process(delta):
	process_key_nosend(MENU, KEY_ENTER)
	process_key_nosend(ACCEPT, KEY_ENTER)
	process_key_nosend(CANCEL, KEY_ESCAPE)
	
	if Com.game.chat and Com.game.chat.has_focus():
		return
	
	process_key_nosend(MAP, KEY_BACKSPACE)
	process_key_nosend(CHAT, KEY_T)
	process_key_nosend(COMMAND, KEY_SLASH)
	
	if Com.game.is_menu:
		process_key_nosend(UP, KEY_UP)
		process_key_nosend(DOWN, KEY_DOWN)
		process_key_nosend(RIGHT, KEY_RIGHT)
		process_key_nosend(LEFT, KEY_LEFT)
		process_key_nosend(JUMP, KEY_SPACE)
		return
	
	process_key(UP, KEY_UP)
	process_key(RIGHT, KEY_RIGHT)
	process_key(LEFT, KEY_LEFT)
	process_key(JUMP, KEY_SPACE)
	process_key(ATTACK, KEY_CONTROL)

func process_key(key_id, key):
	if Input.is_key_pressed(key) and !controls.has(key_id):
		Network.send_data(Packet.new(Packet.TYPE.KEY_PRESS).add_u8(key_id))
		process_key_nosend(key_id, key)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		Network.send_data(Packet.new(Packet.TYPE.KEY_RELEASE).add_u8(key_id))
		process_key_nosend(key_id, key)

func process_key_nosend(key_id, key):
	if Input.is_key_pressed(key) and !controls.has(key_id):
		controls[key_id] = true
		Com.press_key(key_id)
		if !Com.game.is_menu:
			press_key(Com.player.id, key_id)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		controls.erase(key_id)
		Com.release_key(key_id)
		if !Com.game.is_menu:
			release_key(Com.player.id, key_id)

func press_key(player_id, key):
	emit_signal("key_press", player_id, key)

func release_key(player_id, key):
	emit_signal("key_release", player_id, key)