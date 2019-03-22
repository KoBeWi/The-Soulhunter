extends KinematicBody2D
var attack_type = "N"
var synced = false
var rng = {}

var id = -1
onready var players = get_node("../../../Players").get_children()
onready var mapid = $"../..".mapid

func init(name = ""):
	if !Com.server and !synced:
		queue_free()
		return
	
	add_to_group("enemies")
	if id == -1: id = $"../../..".get_enemy_number()
	
	if Com.server:
		Network.send_data(["ENEMY", mapid, id, 0]) #0 to ma być id wroga (tutaj szkielet)

func _body_enter(body):
	if Com.server and is_in_group("enemies") and body.is_in_group("players"):
		Network.send_data(["DAMAGE", mapid, "e", id, body.id, attack_type])

func damage(amount):
	pass
#	print(" >> ", id)

func dead():
	queue_free()

func create_drop(id):
	var item = load("res://Nodes/Item.tscn").instance()
	item.set_id(id)
	item.position = position
	get_node("../..").add_child(item)

func create_soul(id):
	if Com.server: return #nie powinno być potrzebne
	
	var soul = load("res://Nodes/Soul.tscn").instance()
	get_node("../..").add_child(soul)
	soul.position = position
	soul.set_id(id)

func get_sync_data(): return []
func sync_data(data): breakpoint

func server_random(i, id, filter = {}):
	if Com.server:
		var rnd = randi() % i
		if filter.has("eq") and filter["eq"] != rnd: return rnd
		
		Network.send_data(["RNG", mapid, "e", get_index(), id, rnd])
		return rnd
	else:
		#if get_index() == 0: print(rng , "/" , id)
		if rng.has(id):
			var rnd = rng[id]
			rng.erase(id)
			return rnd
		else:
			return -1