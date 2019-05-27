extends Control

enum {ITEM, ENEMY, SOUL}

func _ready():
	Network.connect("item_get", self, "on_item_get")
	Network.connect("soul_get", self, "on_soul_get")

func on_item_get(item):
	push_label(ITEM, [item])

func on_soul_get(soul):
	push_label(SOUL, [soul])

func push_label(type, data):
	var label = preload("res://Nodes/UI/InfoLabel.tscn").instance()
	label.rect_position.y -= get_child_count() * 32
	add_child(label)
	
	match type:
		ITEM:
			var item = Res.get_res(Res.items, data[0])
			label.set_text(item.name)
			label.set_icon(Res.item_icon(item.name))
		SOUL:
			var soul = Res.get_res(Res.souls, data[0])
			label.set_text(soul.name)
			label.set_icon(preload("res://Graphics/Objects/Soul.png"))

func free_label(label):
	label.queue_free()
	
	for other_label in get_children():
		if other_label.get_index() > label.get_index():
			other_label.move_down(other_label.get_index() - label.get_index())