extends Node

var client
var account

const server_host = "127.0.0.1"
#const server_host = "149.156.43.54"
#const server_host = "172.19.56.150"
#const server_host = "172.19.24.145"
const server_port = 2412
#const server_host = "0.tcp.ngrok.io"
#const server_port = 18136

signal connected
signal log_in
signal error

func _ready():
	set_process(false)

func connect_client():
	client = StreamPeerTCP.new()
	client.connect_to_host(server_host, server_port)
	set_process(true)

func _process(delta):
	if client.get_status() == client.STATUS_CONNECTING:
		return
	
	if client.get_status() != client.STATUS_CONNECTED:
		client.connect_to_host(server_host, server_port)
	
	var packet_size = client.get_partial_data(1)
	
	if packet_size[0] == FAILED: return
	
	if packet_size[1].size() > 0 and packet_size[1][0] > 0: #to drugie nie powinno się dziać ;_;
#		print("Received data: ", packet_size[1][0]-1)
		var data = client.get_data(packet_size[1][0]-1)
#		print(client.get_status())
#		print(data[0])
		process_data(data[1])

func process_data(data):
	if data.size() <= 0: return
	var command = extract_string(data, 0)
	print("Received: " + command)
	
	data = extract_data(data, command)
	
	match command:
		"HELLO": emit_signal("connected")
		"LOGIN":
			if data[0] == OK:
				print("OK")
				
				var player = preload("res://Nodes/Player.tscn").instance()
				player.set_main()
				player.id = data[2]
				
				Com.game = preload("res://Scenes/InGame.tscn").instance()
				
				$"/root".add_child(Com.game)
				Com.game.load_map(data[1])
				
				Com.game.add_main_player(player)
				Com.game.update_camera()
				
				emit_signal("log_in")
				
				send_data(["GETSTATS", "1"]) #nie powinno być domyślne?
				send_data(["GETMAP"])
			else:
				emit_signal("error", data[0])
		"REGISTER":
			emit_signal("error", data[0])
		"NEWROOM":
			Com.server.create_room(data[0])
		"REMROOM":
			Com.server.remove_room(data[0])
	
		"CHANGEROOM": Com.game.change_map(data[0])
		"CHAT": Com.game.chat.get_node("..").add_message(data[1], data[2], data[0])
		"DAMAGE": Com.game.damage_number(data[0], data[1], data[2])
		"DEAD":
			var map = determine_map(data).get_parent()
			
			if data[0] == "e":
				var enemy = map.get_enemy(data[1])
				if enemy:
					enemy.dead()
				else:
					printerr("WARNING: Wrong enemy id for dead: ", data[1])
			elif data[0] == "player":
				map.get_node("Players/" + data[1]).dead()
		"DROP":
			var map = determine_map(data).get_parent()
			var enemy = map.get_enemy(data[0])
			if enemy:
				enemy.create_drop(data[1])
			else:
				printerr("WARNING: Wrong enemy id for drop: ", data[0])
		"ENTER":
			var player = load("res://Nodes/Player.tscn").instance()
			
			if Com.server:
				player.id = data.back()[1]
				Com.server.players[data.back()[1]] = player
				Com.server.rooms[data.back()[2]].players.add_child(player)
				Com.server.synchronize_player(player.mapid, data.back()[1])
			else:
				Com.game.get_node("Players").add_child(player)
			player.initialize(data.back())
			
			for i in range(data.size() - 2):
				Com.controls.press_key(data.back()[0], data[i])
		"EQUIPMENT": Com.game.update_equipment(data)
		"EXIT":
			var map = determine_map(data).get_parent()
			
			for player in map.get_node("Players").get_children():
				if player.id == data[0]:
					Com.controls.remove_player(player)
					player.queue_free()
		"EXPERIENCE": Com.player.get_node("Character").experience += data[0]
		"INVENTORY": Com.game.update_inventory(data)
		"KEYPRESS": Com.controls.press_key(data[0], data[1])
		"KEYRELEASE": Com.controls.release_key(data[0], data[1])
		"MAP": Com.player.chr.update_map(data)
		"PLAYERID": Com.player.id = data[0]
		"POS":
			var map = determine_map(data)
			
			for player in map.get_node("../Players").get_children():
				if player.id == data[0]:
					var pos = Vector2()
					match data[1]:
						5: pos = map.get_node("SavePoint/PlayerSpot").global_position
						0: pos = Vector2(data[2] * 1920, 0)
						1:
							pos = Vector2(map.width * 1920 - 30, data[2] * 1080 + 540)
							player.flip(true)
						2: pos = Vector2(data[2] * 1920, map.height * 1080 - 1)
						3: pos = Vector2(30, data[2] * 1080 + 540)
					
					player.position = pos
					player.initiated = true
					break
		"RNG":
			var group = data[0]
			var index = data[1]
			
			if group == "e":
				var enemy = Com.game.get_enemy(index)
				if enemy: enemy.rng[data[2]] = data[3]
		"SOUL":
			var enemy = Com.game.get_enemy(data[0])
			if enemy: enemy.create_soul(data[1])
		"STATS":
			var stats = stat_code(data.back())
			var send = {}
			for i in range(stats.size()):
				send[stats[i]] = data[i]
			Com.game.update_stats(send)
		"SYNC":
			var group = data[0]
			var index = data[1]
			
			if group == "p":
				var pos = get_data(["vector2"], data[3], data[2])[0]
				var player = Com.game.get_player(index)
				if player:
					player.position = pos
				else:
					printerr("WARNING: Non-existent player index: ", index)
			elif group == "e":
				var enem_type = extract_string(data[3], data[2])
				var enemy = Com.game.get_enemy(index)
				
#				if enem_type == "Skeleton": print_raw(data[3])
				
				if !enemy:
					enemy = load("res://Nodes/Enemies/" + enem_type + ".tscn").instance()
					enemy.synced = true
					enemy.id = index
					Com.game.enemies.add_child(enemy)
				
				data[2] += enem_type.length()+1
				enemy.sync_data(data)

func send_data(data):
	print("Sending: ", data)
	var size = 1
	var packet = PoolByteArray()
	
	for bit in data:
		if typeof(bit) == TYPE_STRING:
			packet.append_array(bit.to_ascii())
			packet.append(0)
			size += bit.length()+1
		elif typeof(bit) == TYPE_REAL: #trochu hack
			packet.append(int(bit) % 256)
			packet.append(int(bit) / 256)
			size += 2
		elif typeof(bit) == TYPE_INT:
			packet.append(bit % 256)
			packet.append(bit / 256)
			size += 2
		elif typeof(bit) == TYPE_VECTOR2: #ten abs tak średnio
			packet.append(int(abs(bit.x)) % 256)
			packet.append(int(abs(bit.x)) / 256)
			packet.append(int(abs(bit.y)) % 256)
			packet.append(int(abs(bit.y)) / 256)
			size += 4
		elif typeof(bit) == TYPE_BOOL:
			packet.append(1 if bit else 0)
			size += 2
		else:
			print("Something strange went to packet: ", typeof(bit))
			var bytes = var2bytes(bit)
			packet.append_array(bytes)
			size += bytes.size()
	
	packet.insert(0, size)
#	for i in range(packet.size()): printraw(packet[i], " ")
#	print()
	client.put_data(packet)

func print_raw(ary): ##DEBUG
	var arr = []
	for i in range(ary.size()): arr.append(ary[i])
	print(str(arr))

func extract_data(data, command):
	var i = command.length()+1
#	print("'", command, "'", " ", command == "LOGIN")
	
	match command:
		"HELLO": return
		"LOGIN": return get_data(["int", "int", "int"], data, i)
		"REGISTER": return get_data(["int"], data, i)
		
		"CHANGEROOM": return get_data(["int"], data, i)
		"CHAT": return get_data(["int", "string", "string"], data, i)
		"DAMAGE": return get_data(["string", "int", "int"], data, i)
		"DEAD":
			if Com.server:
				return get_data(["string", "int", "int"], data, i)
			else:
				return get_data(["string", "int"], data, i)
		"DROP":
			if Com.server:
				return get_data(["int", "int", "int"], data, i)
			else:
				return get_data(["int", "int"], data, i)
		"ENTER":
			if Com.server:
				var temp = get_data(["int", "string", "int", "int"], data, i)
				var send = get_data(make_format("string", temp[3]), data, temp.back())
				send.append([temp[1], temp[2], temp[0]])
				return send
			else:
				var temp = get_data(["string","int", "int"], data, i)
				var send = get_data(make_format("string", temp[2]), data, temp.back())
				send.append([temp[0], temp[1]])
				return send
		"EQUIPMENT": return get_data(make_format("int", 8), data, i)
		"EXIT": return get_data(["int", "int"], data, i)
		"EXPERIENCE", "PLAYERID": return get_data(["int"], data, i)
		"INVENTORY":
			var temp = get_data(["int"], data, i)
			return get_data(make_format("int", temp[0]), data, temp.back())
		"KEYPRESS", "KEYRELEASE": return get_data(["string", "string"], data, i)
		"MAP":
			var temp = get_data(["int"], data, i)
			return get_data(make_format("int", temp[0]), data, temp.back())
		"POS":
			if Com.server:
				return get_data(["int", "int", "int", "int"], data, i)
			else:
				return get_data(["int", "int", "int"], data, i)
		"RNG": return get_data(["string", "int", "string", "int"], data, i)
		"SOUL": return get_data(["int", "int"], data, i)
		"STATS":
			var temp = get_data(["int"], data, i)
			var send = get_data(make_format("int", stat_code(temp[0]).size()), data, temp.back())
			send.append(temp[0])
			return send
		"SYNC":
#			print_raw(data)
			var send = get_data(["string", "int"], data, i)
			return send + [data]
		_: print("Unknown command: ", command, " (", command.to_ascii().size(), ")")

func get_data(format, data, start):
	var i = start
	var result = []
	
	for type in format: #TODO: enum lub TYPE_STRING etc.
		if i >= data.size():
			return result
		
		if type == "string":
			var string = extract_string(data, i)
			result.append(string)
			i += string.length()+1
		elif type == "int":
			result.append(extract_int(data, i))
			i += 2
		elif type == "vector2":
			result.append(Vector2(extract_int(data, i), extract_int(data, i+2)))
			i += 4
	
	result.append(i)
	return result

func extract_string(raw_ary, start):
	var string = []
	var i = start
	
	while raw_ary[i] > 0:
#		print("str(", raw_ary[i], ")")
		string.append(raw_ary[i])
		i += 1
	
	return PoolByteArray(string).get_string_from_ascii()
	
func extract_int(raw_ary, start):
	return raw_ary[start]*256 + raw_ary[start+1]

func make_format(format, length):
	var temp = []
	
	for i in range(length):
		temp.append(format)
	
	return temp

func stat_code(code):
	if code == 1:
		return ["level", "experience", "maxhp", "hp", "maxmp", "mp"]
	elif code == 2:
		return ["attack", "defense"]
		
func determine_map(source):
	if Com.server: return Com.server.rooms[source[-2]].root.map
	else: return Com.game.map