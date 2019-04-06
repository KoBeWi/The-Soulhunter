extends Panel

const default_chats = ["System", "Global", "Local", "Whisper"]
const chat_colors = [Color(0.8, 0.8, 0.8), Color(1, 1, 0.4), Color(0.3, 0.5, 1), Color(0.7, 0.2, 1)]

onready var font = load("res://Resources/UI/DefaultFont.tres")

var mode = Data.CHATS.GLOBAL
var whisper = ""
var history = []

onready var input = $Input

func _ready():
	Com.controls.connect("key_press", self, "on_key_press")
	Com.controls.connect("key_release", self, "on_key_release")
	Network.connect("chat_message", self, "on_message_get")

func _draw():
	var lines = min(7, history.size())
	
	for i in range(lines):
		var message = history[history.size() - i - 1]
		draw_string(font, Vector2(4, 112 - i * 16), chat_label(message) + ") ", chat_color(message))
		draw_string(font, Vector2(72, 112 - i * 16), message["text"])

func on_message_get(type, from, message):
	add_message(from, message, type)

func add_message(author, message, type = mode):
	history.append({"type": type, "text": author + ": " + message, "whisper": whisper})
	update()

func chat_label(message):
	return default_chats[message["type"]]

func chat_color(message):
	return chat_colors[message["type"]]

func parse_command(command):
	if command == "/g":
		mode = Data.CHATS.GLOBAL
	elif command == "/l":
		mode = Data.CHATS.LOCAL
	elif command.left(2) == "/w":
		var split = command.split(" ", true, 1)
		if split.size() == 2:
			mode = 3
			whisper = split[1]
	
	if mode != 3: whisper = ""

func on_key_press(p_id, key, state):
	if state == Controls.State.ACTION:
		if key == Controls.CHAT:
			Com.controls.state = Controls.State.CHAT
			input.placeholder_text = ""
			input.grab_focus()
			return
		else:
			return
	elif state == Controls.State.CHAT:
		if key == Controls.ACCEPT:
			if input.text.begins_with("/"):
				parse_command(input.text)
			else:
				add_message(Com.player.uname, input.text)
				Packet.new(Packet.TYPE.CHAT).add_u8(mode).add_string(input.text).send()
			
			reset()
		elif key == Controls.CANCEL:
			reset()

func on_key_release(p_id, key, state):
	pass

func reset():
	input.text = ""
	input.placeholder_text = "Press T to chat"
	input.release_focus()
	
	if Com.controls.state == Controls.State.CHAT:
		Com.controls.state = Controls.State.ACTION