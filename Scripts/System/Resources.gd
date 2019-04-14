extends Node

var maps = []
var items = []
var souls = []

func _ready():
	var dir = Directory.new()
	if dir.open("res://Maps") == OK:
		dir.list_dir_begin(true)
		
		var file_name = dir.get_next()
		while file_name != "":
			var map  = load("res://Maps/" + file_name)
			var map_id = map.get_state().get_node_property_value(0, 2)
			
			maps.resize(max(maps.size(), map_id + 1))
			maps[map_id] = map
			
			file_name = dir.get_next()
	else:
		print("MAP DIRECTORY DOESN'T EXIST WTF")
	
	read_generic_resources("Items", items)
	read_generic_resources("Souls", souls)

func read_generic_resources(resource, target):
	var dir = Directory.new()
	if dir.open("res://Resources/" + resource) == OK:
		dir.list_dir_begin(true)
		
		var file_name = dir.get_next()
		while file_name != "":
			target.resize(max(target.size(), int(file_name) + 1))
			
			var file = File.new()
			file.open("res://Resources/" + resource + "/" + file_name, file.READ)
			var text = file.get_as_text()
			file.close()
			
			var dict = parse_json(text)
			target[int(file_name)] = dict
			
			file_name = dir.get_next()
	else:
		print(resource.to_upper() + " DIRECTORY DOESN'T EXIST DAFUQ")