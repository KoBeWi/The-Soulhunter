class_name Controls
extends Node

enum{ATTACK, JUMP, UP, RIGHT, DOWN, LEFT, SOUL, ACCEPT, CANCEL, MAP, MENU, CHAT, COMMAND, CLOSE_CHAT}
const NAMES = ["ATTACK", "JUMP", "UP", "RIGHT", "DOWN", "LEFT", "SOUL", "ACCEPT", "CANCEL", "MAP", "MENU", "CHAT", "COMMAND", "CLOSE_CHAT"]

enum State{NONE, ACTION, CHAT, MENU, MAP, GAME_OVER}
var state = State.NONE

var players = {}
var controls = {}

var mappping = {
	ATTACK : KEY_CONTROL,
	JUMP : KEY_SPACE,
	UP : KEY_UP,
	RIGHT : KEY_RIGHT,
	DOWN : KEY_DOWN,
	LEFT : KEY_LEFT,
	SOUL : KEY_SHIFT,
	ACCEPT : KEY_ENTER,
	CANCEL : KEY_BACKSPACE,
	MAP : KEY_TAB,
	MENU : KEY_BACKSLASH,
	CHAT : KEY_T,
	COMMAND : KEY_SLASH,
	CLOSE_CHAT : KEY_ESCAPE
}

signal key_press(p_id, key, state)
signal key_release(p_id, key, state)

func _ready():
	set_process(false)

func _process(delta):
	match state:
		State.ACTION:
			process_key_local(MENU)
			process_key_local(MAP)
			process_key_local(CHAT)
			process_key_local(COMMAND)
			
			process_key(RIGHT)
			process_key(LEFT)
			process_key(UP)
			process_key(DOWN)
			process_key(JUMP)
			process_key(ATTACK)
			process_key(SOUL)
		
		State.CHAT:
			process_key_local(ACCEPT)
			process_key_local(CLOSE_CHAT)
		
		State.MENU:
			process_key_local(MENU)
			process_key_local(ACCEPT)
			process_key_local(CANCEL)
			process_key_local(SOUL)
			process_key_local(MAP)
			
			process_key_local(CHAT)
			process_key_local(COMMAND)
			process_key_local(CLOSE_CHAT)
			
			process_key_local(UP)
			process_key_local(DOWN)
			process_key_local(RIGHT)
			process_key_local(LEFT)
		
		State.MAP:
			process_key_local(UP)
			process_key_local(DOWN)
			process_key_local(RIGHT)
			process_key_local(LEFT)
			process_key_local(MAP)
			
			process_key_local(CHAT)
			process_key_local(COMMAND)
		
		State.GAME_OVER:
			process_key_local(ACCEPT)
			process_key_local(CANCEL)
			
			process_key_local(CHAT)
			process_key_local(COMMAND)

func process_key(key_id):
	var key = mappping[key_id]
	
	if Input.is_key_pressed(key) and !controls.has(key_id):
		Packet.new(Packet.TYPE.KEY_PRESS).add_u8(key_id).send()
		process_key_local(key_id)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		Packet.new(Packet.TYPE.KEY_RELEASE).add_u8(key_id).send()
		process_key_local(key_id)

func process_key_local(key_id):
	var key = mappping[key_id]
	
	if Input.is_key_pressed(key) and !controls.has(key_id):
		controls[key_id] = true
		Com.press_key(key_id)
		if Com.player and is_instance_valid(Com.player) and Com.player.has_meta("id"):
			press_key(Com.player.get_meta("id"), key_id)
		else:
			press_key(-1, key_id)
	elif !Input.is_key_pressed(key) and controls.has(key_id):
		controls.erase(key_id)
		Com.release_key(key_id)
		if Com.player and is_instance_valid(Com.player) and Com.player.has_meta("id"):
			release_key(Com.player.get_meta("id"), key_id)
		else:
			release_key(-1, key_id)

var pressed_keys = {}

func press_key(player_id, key, state_override = state):
	emit_signal("key_press", player_id, key, state_override)

func release_key(player_id, key, state_override = state):
	emit_signal("key_release", player_id, key, state_override)