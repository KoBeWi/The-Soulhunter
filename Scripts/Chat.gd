extends Control

const default_chats = ["System", "Global", "Local", "Whisper"]
const chat_colors = [Color(0.8, 0.8, 0.8), Color(1, 1, 0.4), Color(0.3, 0.5, 1), Color(0.7, 0.2, 1)]

onready var font = load("res://Resources/UI/DefaultFont.tres")

var mode = Data.CHATS.GLOBAL
var whisper = ""

onready var history = $Container/History
onready var input = $Container/Input

func _ready():
	Com.controls.connect("key_press", self, "on_key_press")
	Network.connect("chat_message", self, "on_message_get")

func on_message_get(type, from, message):
	add_message(from, message, type)

func add_message(author, message, type = mode, add_whisper = false):
	history.push_color("#" + chat_colors[type].to_html())
	history.add_text(str("[", default_chats[type], (" to " + whisper) if add_whisper else "", "]"))
	history.pop()
	
	history.push_color("#" + chat_colors[type].lightened(0.5).to_html())
	history.append_bbcode(str(" [b]", author, ":[/b] "))
	history.pop()
	
	history.add_text(str(message, "\n"))

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

func on_key_press(p_id, key, state):
	if state == Controls.State.ACTION:
		if key == Controls.CHAT:
			return activate()
		elif key == Controls.COMMAND:
			activate()
			input.text = "/"
			input.caret_position = 1
			return
		else:
			return
	elif state == Controls.State.CHAT:
		if key == Controls.ACCEPT:
			if input.text.begins_with("/"):
				parse_command(input.text)
			else:
				add_message(Com.player.uname, input.text, mode, mode == Data.CHATS.WHISPER)
				var packet = Packet.new(Packet.TYPE.CHAT).add_u8(mode).add_string(input.text)
				
				if mode == Data.CHATS.WHISPER:
					packet.add_string(whisper)
				
				packet.send()
			
			reset()
		elif key == Controls.CANCEL:
			reset()

func activate():
	Com.controls.state = Controls.State.CHAT
	history.scroll_active = true
	input.placeholder_text = ""
	input.grab_focus()

func reset():
	input.text = ""
	history.scroll_active = false
	input.placeholder_text = "Press T to chat"
	input.release_focus()
	
	if Com.controls.state == Controls.State.CHAT:
		Com.controls.state = Controls.State.ACTION