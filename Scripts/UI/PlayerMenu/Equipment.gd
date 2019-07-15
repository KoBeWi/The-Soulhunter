extends VBoxContainer

export(NodePath) var main = @"../../.."

onready var slots = $Equipment
onready var inventory = $Inventory
onready var description = $Description

var select = 0
var inventory_select = -1

func _ready():
	for slot in slots.get_children():
		slot.clear_item()
	for slot in inventory.get_children():
		slot.clear_item()
	
	main = get_node(main)
	select()

func update_equipment(items):
	for i in 8:
		if items[i] > 0:
			slots.get_child(i).set_item(Res.get_res(Res.items, items[i]).name)
		else:
			slots.get_child(i).clear_item()
	
	select()

func update_equipment_inventory(items = []):
	var available = []
	var filter = get_filter()
	
	for stack in main.stacks.values():
		if Res.items[stack.item].type in filter:
			available.append(stack)
	
	for i in inventory.get_child_count():
		if i < available.size():
			inventory.get_child(i).set_item(available[i])
		else:
			inventory.get_child(i).clear_item()
	
	select_inventory()

func select():
	slot_help()
	var selected = slots.get_child(select)
	for slot in slots.get_children():
		slot.select(selected, !is_slot_selected())
	
	if selected.empty():
		description.visible = false
	else:
		description.visible = true
		
		var item = selected.item_name
		description.get_node("Panel2/Text").text = Res.items[item].description
		description.get_node("Panel1/Icon").texture = Res.item_icon(item)
	
	update_equipment_inventory()

func select_inventory():
	if inventory_select > -1:
		inventory_help()
		var selected = inventory.get_child(inventory_select)
		for slot in inventory.get_children():
			slot.select(selected)
		
		if selected.empty():
			description.visible = false
			preview_stats(null)
		else:
			description.visible = true
			var item = selected.stack_item
			description.get_node("Panel2/Text").text = Res.items[item].description
			description.get_node("Panel1/Icon").texture = Res.item_icon(item)
			preview_stats(item)
	else:
		for slot in inventory.get_children():
			slot.select(null)

func get_filter():
	match select:
		0:
			return ["weapon"]
		1:
			if false: #dual-wield
				return ["weapon", "shield"]
			else:
				return ["shield"]
		2:
			return ["armor"]
		3:
			return ["helmet"]
		4:
			return ["legs"]
		5:
			return ["boots"]
		6:
			return ["cape"]
		7, 8:
			return ["accessory"]

func is_slot_selected():
	return inventory_select != -1

func on_press_key(key):
	if !is_slot_selected():
		var old_select = select
		if key == Controls.RIGHT:
			select = min(select + 1, slots.get_child_count()-1)
		elif key == Controls.LEFT:
			select = max(select - 1, 0)
		elif key == Controls.DOWN:
			select = min(select + inventory.columns, slots.get_child_count()-1)
		elif key == Controls.UP:
			select = max(select - inventory.columns, 0)
		
		if key == Controls.ACCEPT:
			inventory_select = 0
			select()
		
		if key == Controls.SOUL:
			unequip_item()
		
		if select != old_select:
			select()
	else:
		var old_select = inventory_select
		if key == Controls.RIGHT:
			inventory_select = min(inventory_select + 1, inventory.get_child_count()-1)
		elif key == Controls.LEFT:
			inventory_select = max(inventory_select - 1, 0)
		elif key == Controls.DOWN:
			inventory_select = min(inventory_select + inventory.columns, inventory.get_child_count()-1)
		elif key == Controls.UP:
			inventory_select = max(inventory_select - inventory.columns, 0)
		
		if key == Controls.ACCEPT:
			equip_item()
			
		if key == Controls.CANCEL:
			inventory_select = -1
			select()
			preview_stats(null)
		
		if inventory_select != old_select:
			select_inventory()

func equip_item():
	var selected = inventory.get_child(inventory_select)
	
	if !selected.empty():
		Packet.new(Packet.TYPE.EQUIP).add_u8(select).add_u8(selected.stack.origin).send()
		inventory_select = -1
		select()

func unequip_item():
	var selected = slots.get_child(select)
	
	if !selected.empty():
		Packet.new(Packet.TYPE.EQUIP).add_u8(select).add_u8(255).send()
		inventory_select = -1
		select()

func preview_stats(item):
	main.preview_stats(item, slots.get_child(select).item_name)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		if is_slot_selected():
			inventory_help()
		else:
			slot_help()

func inventory_help():
	main.get_help("Select").visible = true
	main.get_help("Select").set_text("Equip")
	main.get_help("Unequip").visible = false
	main.get_help("Cancel").visible = true

func slot_help():
	main.get_help("Select").visible = true
	main.get_help("Select").set_text("Select")
	main.get_help("Unequip").visible = true
	main.get_help("Cancel").visible = false