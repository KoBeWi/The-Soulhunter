extends Node

var level = 1
var experience = 0
var hp = 100
var max_hp = 100
var mp = 80
var max_mp = 80
var attack = 10
var defense = 10

var map = []

var inventory = {}
var equipment = [65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535] #rozmiar powinen być dynamiczny

func _ready():
	pass

func update_inventory(items):
	inventory.clear()
	for i in range(items.size() - 1):
		if inventory.has(items[i]):
			inventory[items[i]] += 1
		else:
			inventory[items[i]] = 1

func update_equipment(items):
	equipment.clear()
	for i in range(8):
		equipment.append(items[i])

func update_map(rooms):
	map.clear()
	for i in range(rooms.size()/2):
		map.append([rooms[i*2], rooms[i*2+1]])

func slot_from_type(type):
	if ["helmet", "hat", "cap"].has(type):
		return "head"
	elif ["armor", "vest", "clothing"].has(type):
		return "torso"
	elif ["shoes", "boots", "socks"].has(type):
		return "feet"
	elif ["weapon", "shield"].has(type):
		return "hand"
	elif ["accessory"].has(type):
		return "accessory"
	elif ["cape", "cloak", "aura"].has(type):
		return "body"
	elif ["consumable"].has(type):
		return "consumable"