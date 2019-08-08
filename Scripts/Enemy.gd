class_name Enemy
extends KinematicBody2D

onready var players = get_tree().get_nodes_in_group("players")

export(String) var enemy_name
export(int) var attack = 10
var stats = {hp = 1}
var last_attacker

func init():
	set_meta("enemy", enemy_name)
	set_meta("attackers", [])
	
	stats = Res.enemies[enemy_name].duplicate()
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
	if body.is_in_group("player_attack"):
		if body.player:
			last_attacker = body.player.get_meta("id")
		
		if Com.is_server:
			if has_meta("attackers"):
				var id = body.player.get_meta("id")
				
				if !get_meta("attackers").has(id):
					get_meta("attackers").append(id)
			
			if body.has_method("on_hit"):
				body.on_hit()
			
			damage(body.attack())
			on_hit()

func unhit(body):
	on_unhit()

func on_hit(): pass
func on_unhit(): pass

func pop_name(damage):
	if enemy_name:
		Com.emit_signal("enemy_attacked", self, damage)

func damage(attack):
	var damage = attack.damage
	stats.hp -= damage
	get_meta("room").Damage(get_meta("id"), damage)
	
	if stats.hp <= 0:
		dead()

func dead():
	on_dead()
	create_drop()
	create_soul()
	Com.dispose_node(self)

func on_dead(): pass

func create_drop():
	var drop = get_random(stats.get("drops", {}))
	
	if drop > -1:
		var item = load("res://Nodes/Objects/Item.tscn").instance()
		item.item = Res.items[stats.drops[drop].name].id
		item.position = position
		get_parent().call_deferred("add_child", item)

func create_soul():
	var soul_drop = get_random(stats.get("souls", {}))
	
	if soul_drop > -1 and last_attacker:
		get_meta("room").SoulGet(last_attacker, Res.souls[stats.souls[soul_drop].name].id)
		
		var soul = load("res://Nodes/Effects/Soul.tscn").instance()
		soul.soul = stats.souls[soul_drop].name
		soul.position = position
		soul.player_id = last_attacker
		get_parent().call_deferred("add_child", soul)

func get_random(from):
	if from.empty(): return -1
	
	var i = -1
	var full_sum = 0
	for drop in from: full_sum += int(drop.chance)
	var sum = 1000 - full_sum
	
	var random = randi() % 1000
	while sum < random:
		i += 1
		sum += from[i].chance
	
	return i

func _dispose():
	Com.dispose_node(self)