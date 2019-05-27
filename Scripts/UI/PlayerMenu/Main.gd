extends Control

const MAIN_STAT_LIST = ["attack", "defense", "magic_attack", "magic_defense", "luck"]
const STAT_LABELS = {attack = "ATKValue", defense = "DEFValue", magic_attack = "MATKValue", magic_defense = "MDEFValue", luck = "LCKValue"}

onready var main_stats = $Container/SheetContainer/CharacterSheet/Stats
onready var tabs = $Container/Tabs
onready var buttons = $Container/Buttons

var current_tab
var tab_buttons = ButtonGroup.new()

var stacks = {}
var newest_stats = {}

func _ready():
	visible = false
	Com.controls.connect("key_press", self, "on_key_press")
	Network.connect("stats", $Container/Tabs/Stats, "update_stats")
	Network.connect("stats", self, "update_stats")
	Network.connect("inventory", $Container/Tabs/Inventory, "update_inventory")
	Network.connect("inventory", $Container/Tabs/Equipment, "update_equipment_inventory")
	Network.connect("equipment", $Container/Tabs/Equipment, "update_equipment")
	
	for button in buttons.get_children():
		button.set_button_group(tab_buttons)
	
	change_tab(0)

func update_stats(stats):
	for stat in MAIN_STAT_LIST:
		if stat in stats:
			set_main_stat(stat, stats[stat])
	
	for stat in stats:
		newest_stats[stat] = stats[stat]

func set_main_stat(stat, value, compare = false):
	var node = main_stats.get_node(STAT_LABELS[stat])
	var old_value = newest_stats.get(stat, 0)
	node.text = str(value)
	
	if compare:
		if old_value > value:
			node.modulate = Color.hotpink
		elif old_value < value:
			node.modulate = Color.cyan
		else:
			node.modulate = Color.white
	else:
		node.modulate = Color.white

func on_key_press(p_id, key, state):
	if state == Controls.State.ACTION:
		if key == Controls.MENU:
			activate()
	elif state == Controls.State.MENU:
		if key == Controls.MENU:
			deactivate()
		
		if key == Controls.SWAP:
			change_tab((current_tab+1) % tabs.get_child_count())
		
		tabs.get_child(current_tab).on_press_key(key)

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

func preview_stats(item, item2):
	if item:
		var data = Res.items[item]
		var data2 = Res.items[item2]
		
		for stat in MAIN_STAT_LIST:
			if stat in data:
				set_main_stat(stat, newest_stats[stat] + data[stat] - data2.get(stat, 0), true)
	else:
		for stat in MAIN_STAT_LIST:
			set_main_stat(stat, newest_stats[stat])