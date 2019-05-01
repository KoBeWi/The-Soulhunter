extends Control

onready var main_stats = $Container/SheetContainer/CharacterSheet/Stats
onready var tabs = $Container/Tabs
onready var buttons = $Container/Buttons

onready var inventory = $Container/Tabs/Inventory/Slots
onready var inventory_description = $Container/Tabs/Inventory/Description

onready var equipment = $Container/Tabs/Equipment/Equipment
onready var equipment_inventory = $Container/Tabs/Equipment/Inventory
onready var equipment_description = $Container/Tabs/Equipment/Description

enum TABS{STATS, INVENTORY, EQUIPMENT, SOULS}

var current_tab
var tab_buttons = ButtonGroup.new()

var inventory_select = 0
var equipment_select = 0
var equipment_inventory_select = -1

func _ready():
	visible = false
	Com.controls.connect("key_press", self, "on_key_press")
	Network.connect("stats", self, "update_stats")
	
	for button in buttons.get_children():
		button.set_button_group(tab_buttons)
	
	for slot in inventory.get_children():
		slot.clear_item()
	select_inventory()
	
	for slot in equipment.get_children():
		slot.clear_item()
	for slot in equipment_inventory.get_children():
		slot.clear_item()
	select_equipment()
	select_equipment_inventory()
	
	change_tab(TABS.STATS)

func update_stats(stats):
	if "attack" in stats:
		main_stats.get_node("ATKValue").text = str(stats["attack"])
	
	if "defense" in stats:
		main_stats.get_node("DEFValue").text = str(stats["defense"])
	
	if "magic_attack" in stats:
		main_stats.get_node("MATKValue").text = str(stats["magic_attack"])
	
	if "magic_defense" in stats:
		main_stats.get_node("MDEFValue").text = str(stats["magic_defense"])
	
	if "luck" in stats:
		main_stats.get_node("LCKValue").text = str(stats["luck"])

func on_key_press(p_id, key, state):
	if state == Controls.State.ACTION:
		if key == Controls.MENU:
			activate()
	elif state == Controls.State.MENU:
		if key == Controls.MENU:
			deactivate()
		
		if key == Controls.ACCEPT:
			pass
		elif key == Controls.CANCEL:
			pass
		
		if key == Controls.SWAP:
			change_tab((current_tab+1) % TABS.size())
		
		if current_tab == TABS.INVENTORY:
			var old_select = inventory_select
			if key == Controls.RIGHT:
				inventory_select = min(inventory_select + 1, inventory.get_child_count()-1)
			elif key == Controls.LEFT:
				inventory_select = max(inventory_select - 1, 0)
			elif key == Controls.DOWN:
				inventory_select = min(inventory_select + inventory.columns, inventory.get_child_count()-1)
			elif key == Controls.UP:
				inventory_select = max(inventory_select - inventory.columns, 0)
			
			if inventory_select != old_select:
				select_inventory()
		
		elif current_tab == TABS.EQUIPMENT:
			if equipment_inventory_select == -1:
				var old_select = equipment_select
				if key == Controls.RIGHT:
					equipment_select = min(equipment_select + 1, equipment.get_child_count()-1)
				elif key == Controls.LEFT:
					equipment_select = max(equipment_select - 1, 0)
				elif key == Controls.DOWN:
					equipment_select = min(equipment_select + inventory.columns, equipment.get_child_count()-1)
				elif key == Controls.UP:
					equipment_select = max(equipment_select - inventory.columns, 0)
				
				if key == Controls.ACCEPT:
					equipment_inventory_select = 0
					select_equipment_inventory()
					select_equipment()
				
				if equipment_select != old_select:
					select_equipment()
			else:
				var old_select = equipment_inventory_select
				if key == Controls.RIGHT:
					equipment_inventory_select = min(equipment_inventory_select + 1, equipment_inventory.get_child_count()-1)
				elif key == Controls.LEFT:
					equipment_inventory_select = max(equipment_inventory_select - 1, 0)
				elif key == Controls.DOWN:
					equipment_inventory_select = min(equipment_inventory_select + inventory.columns, equipment_inventory.get_child_count()-1)
				elif key == Controls.UP:
					equipment_inventory_select = max(equipment_inventory_select - inventory.columns, 0)
					
				if key == Controls.CANCEL:
					equipment_inventory_select = -1
					select_equipment_inventory()
					select_equipment()
				
				if equipment_inventory_select != old_select:
					select_equipment_inventory()

func activate():
	Com.controls.state = Controls.State.MENU
	visible = true

func deactivate():
	Com.controls.state = Controls.State.ACTION
	visible = false

func change_tab(i):
	current_tab = i
	buttons.get_child(i).pressed = true
	
	for tab in tabs.get_child_count():
		tabs.get_child(tab).visible = (current_tab == tab)

func select_inventory():
	var selected = inventory.get_child(inventory_select)
	for slot in inventory.get_children():
		slot.select(selected)
	
	if selected.empty():
		inventory_description.visible = false

func select_equipment():
	var selected = equipment.get_child(equipment_select)
	for slot in equipment.get_children():
		slot.select(selected, equipment_inventory_select == -1)
	
	if selected.empty():
		equipment_description.visible = false

func select_equipment_inventory():
	if equipment_inventory_select > -1:
		var selected = equipment_inventory.get_child(equipment_inventory_select)
		for slot in equipment_inventory.get_children():
			slot.select(selected)
		
		if selected.empty():
			equipment_description.visible = false
	else:
		for slot in equipment_inventory.get_children():
			slot.select(null)

"""
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
	selector.texture = load("res://Graphics/UI/InventorySelect.png")
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
		selector.texture = load("res://Graphics/UI/EquipmentSelect.png")
		selector.position = equipment.position + Vector2(116 + select%2 * 228, select/2 * 40)
		if chr.equipment[eq_slot_order[select]] < 65535:
			update_description(chr.equipment[eq_slot_order[select]])
		else:
			update_description(null)
	else:
		selector.texture = load("res://Graphics/UI/InventorySelect.png")
		select = min(max(select, 0), item_list.size()-1)
		selector.position = inventory.position + Vector2(78 + select%3 * 152, select/3 * 40)
		if select > -1:
			update_description(item_list[select])
		else:
			print("Error: inventory index -1")

func update_description(id):
	if typeof(id) == TYPE_INT:
		description.get_node("Icon").texture = load("res://Graphics/Items/" + str(id) + ".png")
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
		var slot = load("res://Nodes/InventorySpace.tscn").instance()
		if i >= item_list.size():
			slot.get_node("ItemName").text = ""
			slot.texture = load("res://Graphics/UI/InventorySpaceFree.png")
		else:
			var id = item_list[i]
			var name = Res.items[id]["name"]
			if (chr.inventory[id] > 1): name = name + " (x" + str(chr.inventory[id]) + ")"
			slot.get_node("ItemName").text = name
			slot.texture = load("res://Graphics/UI/InventorySpace.png")
		slot.position = Vector2(78 + i%3 * 152, i/3 * 40)
		inventory.add_child(slot)

func update_equipment():
	for slot in equipment.get_children():
		slot.queue_free()
	
	for i in range(8):
		var item = chr.equipment[eq_slot_order[i]]
		var slot = load("res://Nodes/EquipmentSlot.tscn").instance()
		if item == 65535:
			slot.get_node("ItemIcon").texture = null
			slot.get_node("ItemName").text = "<none>"
		else:
			slot.get_node("ItemName").text = Res.items[item]["name"]
			slot.get_node("ItemIcon").texture = load("res://Graphics/Items/" + str(item) + ".png")
		slot.position = Vector2(116 + i%2*228, i/2 * 40)
		equipment.add_child(slot)
"""