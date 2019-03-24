extends Node

enum{STRING, U8, U16}

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
		process_packet(Unpacker.new(data[1]))

func process_packet(unpacker):
#	if data.size() <= 0: return ##inaczej zabezpieczyć
	
	print("Received: " + unpacker.command)
	
	match Unpacker.command:
		"HELLO":
			emit_signal("connected")
		
		"LOGIN":
			var result = unpacker.get_u8()
			
			if result == OK:
				print("Logged in sucessfully")
				
				var player = preload("res://Nodes/Player.tscn").instance()
				player.set_main()
				
				Com.game = preload("res://Scenes/InGame.tscn").instance()
				
				$"/root".add_child(Com.game)
#				Com.game.load_map(data[1])
				
				Com.game.add_main_player(player)
#				Com.game.update_camera()
				
				emit_signal("log_in")
				
#				send_data(["GETSTATS", "1"]) #nie powinno być domyślne? // pwoinno
#				send_data(["GETMAP"])
			else:
				emit_signal("error", result)
		"REGISTER":
			emit_signal("error", unpacker.get_u8())
	
		"CHANGEROOM":
			Com.game.change_map([]) ###
		
		"CHAT":
			Com.game.chat.get_parent().add_message([], [], []) ###
		
		"DAMAGE":
			Com.game.damage_number([], [], []) ###
		
		"DEAD": ###
			var map = determine_map([]).get_parent()
			
			if [][0] == "e":
				var enemy = map.get_enemy([][1])
				if enemy:
					enemy.dead()
				else:
					printerr("WARNING: Wrong enemy id for dead: ", [][1])
			elif [][0] == "player":
				map.get_node("Players/" + [][1]).dead()
		
		"DROP": ###
			var map = determine_map([]).get_parent()
			var enemy = map.get_enemy([][0])
			if enemy:
				enemy.create_drop([][1])
			else:
				printerr("WARNING: Wrong enemy id for drop: ", [][0])
		
		"ENTER":
			var player = load("res://Nodes/Player.tscn").instance()
			
			Com.game.players.add_child(player)
			player.set_name(unpacker.get_string())
			player.id = unpacker.get_u16()
			
#			for i in range(data.size() - 2): ###
#				Com.controls.press_key(data.back()[0], [][i])
		
		"EQUIPMENT": ###
			Com.game.update_equipment([])
		
		"EXIT": ###
			var map = determine_map([]).get_parent()
			
			for player in map.get_node("Players").get_children():
				if player.id == [][0]:
					Com.controls.remove_player(player)
					player.queue_free()
		
		"EXPERIENCE": ###
			Com.player.get_node("Character").experience += [][0]
		
		"INVENTORY": ###
			Com.game.update_inventory([])
		
		"KEYPRESS":
			Com.controls.press_key(unpacker.get_u16(), unpacker.get_u8())
		
		"KEYRELEASE":
			Com.controls.release_key(unpacker.get_u16(), unpacker.get_u8())
		
		"MAP": ###
			Com.player.chr.update_map([])
		
		"POS":
			var player_id = unpacker.get_u16()
			var mode = unpacker.get_u8()
			var offset = unpacker.get_u16()
			
			for player in Com.game.players.get_children():
				if player.id == player_id:
					var pos = Vector2()
					
					match mode:
						0: pos = Vector2(offset * 1920, 0)
						1:
							pos = Vector2(Com.game.map.width * 1920 - 30, offset * 1080 + 540)
							player.flip(true)
						2: pos = Vector2(offset * 1920, Com.game.map.height * 1080 - 1)
						3: pos = Vector2(30, offset * 1080 + 540)
						4: pos = Com.game.map.get_node("SavePoint/PlayerSpot").global_position ##niebezpieczne
						5: pos = Vector2(offset, unpacker.get_u16())
					
					player.position = pos
					player.start()
					break
		"RNG": ###
			var group = [][0]
			var index = [][1]
			
			if group == "e":
				var enemy = Com.game.get_enemy(index)
				if enemy: enemy.rng[[][2]] = [][3]
		"SOUL": ###
			var enemy = Com.game.get_enemy([][0])
			if enemy: enemy.create_soul([][1])
		"STATS": ###
			var stats = stat_code([].back())
			var send = {}
			for i in range(stats.size()):
				send[stats[i]] = [][i]
			Com.game.update_stats(send)
		"SYNC": ###
			var group = [][0]
			var index = [][1]
			
			if group == "p":
				var pos = []#get_data(["vector2"], [][3], [][2])[0]
				var player = Com.game.get_player(index)
				if player:
					player.position = pos
				else:
					printerr("WARNING: Non-existent player index: ", index)
			elif group == "e":
				var enem_type = extract_string([][3], [][2])
				var enemy = Com.game.get_enemy(index)
				
#				if enem_type == "Skeleton": print_raw([][3])
				
				if !enemy:
					enemy = load("res://Nodes/Enemies/" + enem_type + ".tscn").instance()
					enemy.synced = true
					enemy.id = index
					Com.game.enemies.add_child(enemy)
				
				[][2] += enem_type.length()+1
				enemy.sync_data([])

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

func stat_code(code):
	if code == 1:
		return ["level", "experience", "maxhp", "hp", "maxmp", "mp"]
	elif code == 2:
		return ["attack", "defense"]