extends Node
onready var Com = get_node("..")

var players = {}
var controls = {}

func _process(delta):
	if !Com.game : return
	
	process_key_nosend("MENU", KEY_ENTER)
	process_key_nosend("_ACCEPT", KEY_ENTER)
	process_key_nosend("_CANCEL", KEY_ESCAPE)
	if Com.game.chat and Com.game.chat.has_focus(): return
	process_key_nosend("MAP", KEY_BACKSPACE)
	process_key_nosend("CHAT", KEY_T)
	process_key_nosend("_COMMAND", KEY_SLASH)
	if Com.game.is_menu:
		process_key_nosend("UP", KEY_UP)
		process_key_nosend("DOWN", KEY_DOWN)
		process_key_nosend("RIGHT", KEY_RIGHT)
		process_key_nosend("LEFT", KEY_LEFT)
		process_key_nosend("JUMP", KEY_SPACE)
		return
	process_key("UP", KEY_UP)
	process_key("RIGHT", KEY_RIGHT)
	process_key("LEFT", KEY_LEFT)
	process_key("JUMP", KEY_SPACE)
	process_key("ATTACK", KEY_CONTROL)

func process_key(name, key):
	if Input.is_key_pressed(key) and !controls.has(name):
		Network.send_data(["KEYPRESS", name])
		process_key_nosend(name, key)
	elif !Input.is_key_pressed(key) and controls.has(name):
		Network.send_data(["KEYRELEASE", name])
		process_key_nosend(name, key)

func process_key_nosend(name, key):
	if Input.is_key_pressed(key) and !controls.has(name):
		controls[name] = true
		Com.press_key(name)
		if !Com.game.is_menu:
			Com.player.press_key(name)
	elif !Input.is_key_pressed(key) and controls.has(name):
		controls.erase(name)
		Com.release_key(name)
		if !Com.game.is_menu:
			Com.player.release_key(name)

func register_player(player): players[player.uname] = player
func remove_player(player): players.erase(player.uname)

func press_key(player_name, key):
	if players.has(player_name): players[player_name].press_key(key)

func release_key(player_name, key):
	if players[player_name]: players[player_name].release_key(key)