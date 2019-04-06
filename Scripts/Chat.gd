extends Panel

const default_chats = ["System", "Global", "Local", "Whisper"]
const chat_colors = [Color(0.8, 0.8, 0.8), Color(1, 1, 0.4), Color(0.3, 0.5, 1), Color(0.7, 0.2, 1)]

onready var font = load("res://Resources/UI/DefaultFont.tres")

var mode = 1
var whisper = ""
var history = []

func _draw():
	var lines = min(7, history.size())
	
	for i in range(lines):
		var message = history[history.size() - i - 1]
		draw_string(font, Vector2(4, 112 - i * 16), chat_label(message) + ") ", chat_color(message))
		draw_string(font, Vector2(72, 112 - i * 16), message["text"])

func add_message(author, message, type = mode):
	history.append({"type": type, "text": author + ": " + message, "whisper": whisper})
	update()

func chat_label(message):
	return default_chats[message["type"]]

func chat_color(message):
	return chat_colors[message["type"]]

func get_data():
	return [mode, whisper]

func parse_command(command):
	if command == "/g":
		mode = 1
	elif command == "/l":
		mode = 2
	elif command.left(2) == "/w":
		var split = command.split(" ", true, 1)
		if split.size() == 2:
			mode = 3
			whisper = split[1]
	
	if mode != 3: whisper = ""