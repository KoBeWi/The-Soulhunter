extends VBoxContainer

export(NodePath) var main = @"../../.."
export(NodePath) var select_rect = @"../../../SoulSelect"

onready var slots = $Slots
onready var inventory = $Inventory
onready var description = $Description

const SOUL_DESCRIPTIONS = {
	"trigger": "Up + Attack to use",
	"active": "Shift to activate, either toggled or held",
	"augment": "Passive effect on character",
	"enchant": "Passive effect on equipment",
	"extension": "Passive upgrade on other souls",
	"catalyst": "Used for soul forging",
	"ability": "Active special abilities",
	"mastery": "Powerful permanent abilities",
	"identity": "Determines the very essence"
}

var inventory_mode = false
var souls = []
var soul_stacks = {}

var select = 0
var inventory_select = 0

func _ready():
	main = get_node(main)
	select_rect = get_node(select_rect)
	slot_mode()

func on_press_key(key):
	if !inventory_mode:
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
		
		if key == Controls.ACCEPT:
			inventory_mode()
		
		if key == Controls.SOUL:
			unequip_soul()
	else:
		var old_select = inventory_select
		if key == Controls.RIGHT:
			inventory_select = min(inventory_select + 1, inventory.get_child_count()-1)
		elif key == Controls.LEFT:
			inventory_select = max(inventory_select - 1, 0)
		elif key == Controls.DOWN:
			inventory_select = min(inventory_select + inventory.columns, inventory.get_child_count()-1)
		elif key == Controls.UP:
			inventory_select = max(inventory_select - slots.columns, 0)
			
		if inventory_select != old_select:
			select_inventory()
		
		if key == Controls.ACCEPT:
			equip_soul()
			slot_mode()
		
		if key == Controls.CANCEL:
			slot_mode()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			select_rect.visible = true
			if inventory_mode:
				select_inventory()
			else:
				select()
		else:
			select_rect.visible = false

func select():
	var selected = slots.get_child(select)
	select_rect.rect_size = selected.rect_size
	select_rect.rect_position = selected.get_global_rect().position - main.get_global_rect().position
	
	description.visible = true
	description.get_node("Panel2/Text").text = SOUL_DESCRIPTIONS[Soul.TYPE_COLOR.keys()[select]]
	description.get_node("Panel1/Icon").modulate = slots.get_child(select).color

func select_inventory():
	var selected = inventory.get_child(inventory_select)
	select_rect.rect_size = selected.rect_size
	select_rect.rect_position = selected.get_global_rect().position - main.get_global_rect().position
	
	if !selected.empty():
		description.visible = true
		var soul = Res.souls[selected.stack.soul]
		description.get_node("Panel2/Text").text = soul.description + (str("\nMP: ", soul.mp) if "mp" in soul else "")
		description.get_node("Panel1/Icon").modulate = slots.get_child(select).color
	else:
		description.visible = false

func inventory_mode():
	$Slots.visible = false
	$Inventory.visible = true
	
	var slot = slots.get_child(select)
	for item in $Inventory.get_children():
		item.set_color(slot.color)
	
	inventory_mode = true
	inventory_select = 0
	call_deferred("update_inventory")

func slot_mode():
	$Slots.visible = true
	$Inventory.visible = false
	inventory_mode = false
	select()

func sync_souls(data):
	souls = data

func update_inventory():
	soul_stacks = {}
	var category = Soul.TYPE_COLOR.keys()[select]
	
	for i in souls.size():
		var soul = souls[i]
		var data = Res.get_res(Res.souls, soul)
		if data.type != category: continue
		
		if soul in soul_stacks:
			soul_stacks[soul].amount += 1
		else:
			soul_stacks[soul] = {soul = data.name, amount = 1, origin = i}
	
	for i in inventory.get_child_count():
		if i < soul_stacks.size():
			inventory.get_child(i).set_soul(soul_stacks[soul_stacks.keys()[i]])
		else:
			inventory.get_child(i).clear_soul()
	
	select_inventory()

func update_equipment(souls):
	for i in 8:
		if souls[i] > 0:
			slots.get_child(i).set_soul(Res.get_res(Res.souls, souls[i]).name)
		else:
			slots.get_child(i).clear_soul()
	
	select()

func equip_soul():
	var selected = inventory.get_child(inventory_select)
	
	if !selected.empty():
		Packet.new(Packet.TYPE.EQUIP_SOUL).add_u8(select).add_u8(selected.stack.origin).send()
		inventory_select = -1
		select()

func unequip_soul():
	var selected = slots.get_child(select)
	
	if !selected.empty():
		Packet.new(Packet.TYPE.EQUIP_SOUL).add_u8(select).add_u8(255).send()
		inventory_select = -1
		select()