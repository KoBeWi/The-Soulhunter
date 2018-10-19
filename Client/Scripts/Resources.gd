extends Node

var maps = []
var items = []
var souls = []

func _ready():
	var dir = Directory.new()
	if dir.open("res://Maps") == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if name == "." or name == "..":
				name = dir.get_next()
				continue
				
			var map = load("res://Maps/" + name)
			var mapid = map.instance().mapid
			maps.resize(max(maps.size(), mapid + 1))
			maps[mapid] = map
			
			name = dir.get_next()
	else:
		print("MAP DIRECTORY DOESN'T EXIST WTF")
	
	read_generic_resources("Items", items)
	read_generic_resources("Souls", souls)

func read_generic_resources(resource, target):
	var dir = Directory.new()
	if dir.open("res://Resources/" + resource) == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if name == "." or name == "..":
				name = dir.get_next()
				continue
			target.resize(max(target.size(), int(name) + 1))
			
			var file = File.new()
			file.open("res://Resources/" + resource + "/" + name, file.READ)
			var text = file.get_as_text()
			file.close()
			
			var dict = parse_json(text)
			target[int(name)] = dict
			
			name = dir.get_next()
	else:
		print(resource.to_upper() + " DIRECTORY DOESN'T EXIST DAFUQ")