extends Node

var maps = []
var items = {}
var souls = {}
var enemies = {}

func _ready():
	var dir = Directory.new()
	if dir.open("res://Maps") == OK:
		dir.list_dir_begin(true)
		
		var file_name = dir.get_next()
		while file_name != "":
			var map  = load("res://Maps/" + file_name)
			var map_id = map.get_state().get_node_property_value(0, 4)
			
			maps.resize(max(maps.size(), map_id + 1))
			maps[map_id] = map
			
			file_name = dir.get_next()
	else:
		print("MAP DIRECTORY DOESN'T EXIST WTF")
	
	read_generic_resources("Items", items)
	read_generic_resources("Souls", souls)
	read_generic_resources("Enemies", enemies)

func read_generic_resources(resource, target):
	var dir = Directory.new()
	dir.open("res://Resources/Data/" + resource)
	dir.list_dir_begin(true)
	
	var id = 0
	
	var file_name = dir.get_next()
	while file_name != "":
		var file = File.new()
		file.open("res://Resources/Data/" + resource + "/" + file_name, file.READ)
		var text = file.get_as_text()
		
		var ary = parse_json(text)
		for dict in ary:
			target[dict.name] = dict
			dict.id = id
			id += 1
		
		file_name = dir.get_next()

func get_res(from, id):
	for resource in from.values():
		if resource.id == id:
			return resource

func item_icon(item):
	return load(str("res://Graphics/Items/", items[item].id ,".png"))