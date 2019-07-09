extends Control

enum {ENEMY, ITEM, SOUL}

func _ready():
	Network.connect("item_get", self, "on_item_get")
	Network.connect("soul_get", self, "on_soul_get")
	Com.connect("enemy_attacked", self, "on_enemy_attacked")

func on_item_get(item):
	push_label(ITEM, [item])

func on_soul_get(soul):
	push_label(SOUL, [soul])

func on_enemy_attacked(enemy, damage):
	if enemy.has_meta("hp"):
		enemy.set_meta("hp", enemy.get_meta("hp") - damage)
	else:
		enemy.set_meta("hp", enemy.stats.max_hp - damage)
	
	if !enemy.has_meta("label") or !is_instance_valid(enemy.get_meta("label")):
		var label = push_label(ENEMY, [enemy.enemy_name, enemy.get_meta("hp"), enemy.stats.max_hp])
		enemy.set_meta("label", label)
	elif enemy.has_meta("label"):
		enemy.get_meta("label").set_bar(enemy.get_meta("hp"), enemy.stats.max_hp)
		enemy.get_meta("label").restart()

func push_label(type, data):
	var label = preload("res://Nodes/UI/InfoLabel.tscn").instance()
	label.rect_position.y -= get_child_count() * 32
	add_child(label)
	
	match type:
		ENEMY:
			label.set_text(data[0])
			label.set_colors(Color.red)
			label.set_bar(data[1], data[2])
		ITEM:
			var item = Res.get_res(Res.items, data[0])
			label.set_text(item.name)
			label.set_icon(Res.item_icon(item.name))
			label.set_colors(Color.orangered)
		SOUL:
			var soul = Res.get_res(Res.souls, data[0])
			label.set_text(soul.name)
			label.set_icon(preload("res://Graphics/Objects/Soul.png"))
			
			var color = Soul.TYPE_COLOR[soul.type]
			label.set_colors(color.darkened(0.8), color)
	
	return label

func free_label(label):
	label.queue_free()
	
	for other_label in get_children():
		if other_label.get_index() > label.get_index():
			other_label.move_down(other_label.get_index() - label.get_index())