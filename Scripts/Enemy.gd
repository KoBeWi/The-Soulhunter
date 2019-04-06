class_name Enemy
extends KinematicBody2D

onready var players = get_tree().get_nodes_in_group("players")

func on_client_create():
	visible = false
	set_process(false)
	set_physics_process(false)

func on_initialized():
	visible = true
	set_process(true)
	set_physics_process(true)

func init(ename = ""):
	return
#	add_to_group("enemies")
#	if id == -1: id = $"../../..".get_enemy_number()
#
#	if Com.server:
#		Network.send_data(["ENEMY", mapid, id, 0]) #0 to ma być id wroga (tutaj szkielet)

func _process(delta):
	if Com.is_server:
		players = get_tree().get_nodes_in_group("players") #optymalizacja do tego?
		server_ai(delta)

func _physics_process(delta):
	general_ai(delta)

func server_ai(delta): pass
func general_ai(delta): pass

func _body_enter(body):
	return
#	if Com.server and is_in_group("enemies") and body.is_in_group("players"):
#		Network.send_data(["DAMAGE", mapid, "e", id, body.id, attack_type])

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