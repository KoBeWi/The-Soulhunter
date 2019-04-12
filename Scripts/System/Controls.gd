class_name Controls
extends Node

enum{ATTACK, JUMP, UP, RIGHT, DOWN, LEFT, ACCEPT, CANCEL, MAP, MENU, CHAT, COMMAND}

enum State{ACTION, CHAT, MENU}
var state = State.ACTION

signal key_press(p_id, key, state)
signal key_release(p_id, key, state)

var players = {}
var controls = {}

func _ready():
	set_process(false)

func set_master(player):
	set_process(true)

func _process(delta):
	match state:
		State.ACTION:
			process_key_local(MENU, KEY_ENTER)
			process_key_local(MAP, KEY_BACKSPACE)
			process_key_local(CHAT, KEY_T)
			process_key_local(COMMAND, KEY_SLASH)
			
			process_key(UP, KEY_UP)
			process_key(RIGHT, KEY_RIGHT)
			process_key(LEFT, KEY_LEFT)
			process_key(JUMP, KEY_SPACE)
			process_key(ATTACK, KEY_CONTROL)
		
		State.CHAT:
			process_key_local(ACCEPT, KEY_ENTER)
			process_key_local(CANCEL, KEY_ESCAPE)
		
		State.MENU:
			process_key_local(MENU, KEY_ENTER)
			process_key_local(ACCEPT, KEY_ENTER)
			process_key_local(CANCEL, KEY_ESCAPE)
			
			process_key_local(CHAT, KEY_T)
			process_key_local(COMMAND, KEY_SLASH)
			
			process_key_local(UP, KEY_UP)
			process_key_local(DOWN, KEY_DOWN)
			process_key_local(RIGHT, KEY_RIGHT)
			process_key_local(LEFT, KEY_LEFT)
			process_key_local(JUMP, KEY_SPACE)

func process_key(key_id, key):
	if Input.is_key_pressed(key) and !controls.has(key_id):
		Packet.new(Packet.TYPE.KEY_PRESS).add_u8(key_id).send()
		process_key_local(key_id, key)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		Packet.new(Packet.TYPE.KEY_RELEASE).add_u8(key_id).send()
		process_key_local(key_id, key)

func process_key_local(key_id, key):
	if Input.is_key_pressed(key) and !controls.has(key_id):
		controls[key_id] = true
		Com.press_key(key_id)
		press_key(Com.player.get_meta("id"), key_id)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		controls.erase(key_id)
		Com.release_key(key_id)
		release_key(Com.player.get_meta("id"), key_id)

func press_key(player_id, key, state_override = state):
	emit_signal("key_press", player_id, key, state_override)

func release_key(player_id, key, state_override = state):
	emit_signal("key_release", player_id, key, state_override)