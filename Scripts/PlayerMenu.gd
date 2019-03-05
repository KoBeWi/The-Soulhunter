extends Control

const eq_slot_order = [3, 7, 4, 0, 5, 1, 6, 2]

onready var status = $StatusPanel
onready var inventory = $Inventory
onready var equipment = $Equipment
onready var chr = Com.player.get_node("Character")
onready var selector = $InventorySelect
onready var description = $"Description Panel"

var mode = "eq"
var select = 0
var eq_select = 0
var current_type = "consumable"
var item_list = []
var init = true

func _ready():
	pass

func show():
	select = 0
	mode = "inv" if chr.inventory.size() > 0 else "eq"
	current_type = "consumable"
	selector.texture = load("Graphics/UI/InventorySelect.png")
	visible = true

func _process(delta):
	if mode == "eq":
		var old_select = select
		if Com.key_press("DOWN"):
			if select > 5:
				if chr.inventory.size() > 0:
					select = (0 if select == 6 else 2)
					mode = "inv"
					current_type = "consumable"
					update_inventory()
					return
			else:
				select += 2
		if Com.key_press("UP"): select -= 2
		if Com.key_press("RIGHT"): select += 1
		if Com.key_press("LEFT"): select -= 1
		
		if select != old_select:
			select = min(max(select, 0), 7)
			current_type = ["hand", "body", "hand", "head", "accessory", "torso", "accessory", "feet"][select]
			update_inventory()
		
		if Com.key_press("JUMP") and !item_list.empty():
			eq_select = select
			mode = "sel"
	else:
		if Com.key_press("DOWN"): select += 3
		if Com.key_press("UP") and mode == "inv":
			if select < 3:
				select = (7 if select == 2 else 6)
				mode = "eq"
				current_type = ("feet" if select == 2 else "accessory")
				update_inventory()
				return
			else:
				select -= 3
		if Com.key_press("RIGHT"): select += 1
		if Com.key_press("LEFT"): select -= 1
		
		if Com.key_press("JUMP") and mode == "sel":
			Network.send_data(["EQUIP", eq_slot_order[eq_select], item_list[select]])
			mode = "eq"
			if chr.equipment[eq_slot_order[eq_select]] < 65535:
				chr.inventory[chr.equipment[eq_slot_order[eq_select]]] += 1
			chr.equipment[eq_slot_order[eq_select]] = item_list[select]
			chr.inventory[item_list[select]] -= 1
			if chr.inventory[item_list[select]] == 0:
				chr.inventory.erase(item_list[select])
				item_list.remove(item_list[select])
			select = eq_select
			update_equipment()
			update_inventory()
	update_select()

func update_select():
	if mode == "eq":
		selector.texture = load("Graphics/UI/EquipmentSelect.png")
		selector.position = equipment.position + Vector2(116 + select%2 * 228, select/2 * 40)
		if chr.equipment[eq_slot_order[select]] < 65535:
			update_description(chr.equipment[eq_slot_order[select]])
		else:
			update_description(null)
	else:
		selector.texture = load("Graphics/UI/InventorySelect.png")
		select = min(max(select, 0), item_list.size()-1)
		selector.position = inventory.position + Vector2(78 + select%3 * 152, select/3 * 40)
		if select > -1:
			update_description(item_list[select])
		else:
			print("Error: inventory index -1")

func update_description(id):
	if typeof(id) == TYPE_INT:
		description.get_node("Icon").texture = load("Graphics/Items/" + str(id) + ".png")
		description.get_node("Description").text = Res.items[id]["description"]
	else:
		description.get_node("Icon").texture = null
		description.get_node("Description").text = "No item equipped."

func update_status():
	var ui = $"../../UI"
	status.get_node("ATK").text = "ATK " + str(chr.attack)
	status.get_node("DEF").text = "DEF " + str(chr.defense)
	status.get_node("EXP").text = "EXP " + str(chr.experience)
	status.get_node("NEXT").text = "NEXT " + str(ui.total_exp_for_level(chr.level) - chr.experience)

func update_inventory():
	if init and chr.inventory.size() > 0:
		mode = "inv"
	init = false
	
	for slot in inventory.get_children():
		slot.queue_free()
	
	item_list.clear()
	for item in chr.inventory.keys():
		if chr.slot_from_type(Res.items[item]["type"]) == current_type: item_list.append(item)
	
	for i in 9:
		var slot = load("Nodes/InventorySpace.tscn").instance()
		if i >= item_list.size():
			slot.get_node("ItemName").text = ""
			slot.texture = load("Graphics/UI/InventorySpaceFree.png")
		else:
			var id = item_list[i]
			var name = Res.items[id]["name"]
			if (chr.inventory[id] > 1): name = name + " (x" + str(chr.inventory[id]) + ")"
			slot.get_node("ItemName").text = name
			slot.texture = load("Graphics/UI/InventorySpace.png")
		slot.position = Vector2(78 + i%3 * 152, i/3 * 40)
		inventory.add_child(slot)

func update_equipment():
	for slot in equipment.get_children():
		slot.queue_free()
	
	for i in range(8):
		var item = chr.equipment[eq_slot_order[i]]
		var slot = load("Nodes/EquipmentSlot.tscn").instance()
		if item == 65535:
			slot.get_node("ItemIcon").texture = null
			slot.get_node("ItemName").text = "<none>"
		else:
			slot.get_node("ItemName").text = Res.items[item]["name"]
			slot.get_node("ItemIcon").texture = load("Graphics/Items/" + str(item) + ".png")
		slot.position = Vector2(116 + i%2*228, i/2 * 40)
		equipment.add_child(slot)