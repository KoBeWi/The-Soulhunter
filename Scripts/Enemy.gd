class_name Enemy
extends KinematicBody2D

onready var players = get_tree().get_nodes_in_group("players")

export(String) var enemy_name
var stats = {hp = 1}

func on_client_create():
	visible = false
	set_process(false)
	set_physics_process(false)

func on_initialized():
	visible = true
	set_process(true)
	set_physics_process(true)

func init():
	set_meta("enemy", enemy_name)
	set_meta("attackers", [])
	
	stats = Res.enemies[enemy_name]
	stats.hp = stats.max_hp

func _process(delta):
	if Com.is_server:
		players = get_tree().get_nodes_in_group("players") #optymalizacja do tego?
		server_ai(delta)

func _physics_process(delta):
	general_ai(delta)

func server_ai(delta): pass
func general_ai(delta): pass

func hit(body):
	if Com.is_server:
		if body.is_in_group("player_attack"):
			if has_meta("attackers"):
				var id = body.player.get_meta("id")
				
				if !get_meta("attackers").has(id):
					get_meta("attackers").append(id)
			
			damage(body.call("attack"))
			on_hit()

func unhit(body):
	on_unhit()

func on_hit(): pass
func on_unhit(): pass

func damage(attack):
	var damage = attack.damage
	stats.hp -= damage
	get_meta("room").call("Damage", get_meta("id"), damage)
	
	if stats.hp <= 0:
		dead()

func dead():
	on_dead()
	create_drop(stats.get("drops", {}))
	Com.dispose_node(self)

func on_dead(): pass

func create_drop(drops):
	if drops.empty(): return
	
	var i = -1
	var full_sum = 0
	for drop in drops: full_sum += int(drop.chance)
	var sum = 1000 - full_sum
	
	var random = randi() % 1000
	while sum < random:
		i += 1
		sum += drops[i].chance
	
	if i > -1:
		var item = load("res://Nodes/Objects/Item.tscn").instance()
		item.item = Res.items[drops[i].name].id
		item.position = position
		get_parent().call_deferred("add_child", item)

func create_soul(id):
	if Com.server: return #nie powinno być potrzebne
	
	var soul = load("res://Nodes/Soul.tscn").instance()
	get_parent().add_child(soul)
	soul.position = position
	soul.set_id(id)