extends VBoxContainer

export(NodePath) var main = @"../../.."

onready var slots = $Slots
onready var description = $Description

var select = 0

func _ready():
	for slot in slots.get_children():
		slot.clear_item()
	
	main = get_node(main)
	select()

func select():
	var selected = slots.get_child(select)
	for slot in slots.get_children():
		slot.select(selected)
	
	if selected.empty():
		description.visible = false
	else:
		description.visible = true
		
		var item = selected.stack_item
		description.get_node("Panel2/Text").text = Res.items[item].description
		description.get_node("Panel1/Icon").texture = Res.item_icon(item)

func update_inventory(items = []):
	if items is Array:
		main.stacks = {}
		
		for i in items.size():
			var item = items[i]
			
			if item in main.stacks:
				main.stacks[item].amount += 1
			else:
				main.stacks[item] = {item = Res.get_res(Res.items, item).name, amount = 1, origin = i}
	else:
		var item = items
		if item in main.stacks:
			main.stacks[item].amount += 1
		else:
			main.stacks[item] = {item = Res.get_res(Res.items, item).name, amount = 1, origin = main.stacks.size()}
		
	for i in slots.get_child_count():
		if i < main.stacks.size():
			slots.get_child(i).set_item(main.stacks[main.stacks.keys()[i]])
		else:
			slots.get_child(i).clear_item()
	
	select()

func on_press_key(key):
	var old_select = select
	if key == Controls.RIGHT:
		select = min(select + 1, slots.get_child_count()-1)
	elif key == Controls.LEFT:
		select = max(select - 1, 0)
	elif key == Controls.DOWN:
		select = min(select + slots.columns, slots.get_child_count()-1)
	elif key == Controls.UP:
		select = max(select - slots.columns, 0)
	
	if select != old_select:
		select()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		main.get_help("Select").visible = false
		main.get_help("Unequip").visible = false
		main.get_help("Cancel").visible = false