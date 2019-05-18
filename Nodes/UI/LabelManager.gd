extends Control

enum {ITEM, ENEMY, SOUL}

func _ready():
	Network.connect("item_get", self, "on_item_get")

func on_item_get(item):
	push_label(ITEM, [item])

func push_label(type, data):
	var label = preload("res://Nodes/UI/InfoLabel.tscn").instance()
	label.rect_position.y -= get_child_count() * 32
	add_child(label)
	
	match type:
		ITEM:
			var item = Res.get_res(Res.items, data[0])
			label.set_text(item.name)
			label.set_icon(Res.item_icon(item.name))