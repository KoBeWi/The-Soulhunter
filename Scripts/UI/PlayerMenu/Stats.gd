extends HBoxContainer

export(NodePath) var main = @"../../.."

onready var stat_list = $Grid

var level = 1

func _ready():
	main = get_node(main)

func update_stats(stats):
	if "level" in stats:
		level = stats.level
	
	if "exp" in stats:
		stat_list.get_node("EXPValue").text = str(stats.exp)
		stat_list.get_node("NEXTValue").text = str(Com.exp_for_level(level) - stats.exp + Com.total_exp_for_level(level-1))

func on_press_key(key):
	pass

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		main.get_help("Select").visible = false
		main.get_help("Unequip").visible = false
		main.get_help("Cancel").visible = false