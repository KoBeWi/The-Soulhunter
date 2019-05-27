extends HBoxContainer

onready var stat_list = $Grid

var level = 1

func update_stats(stats):
	if "level" in stats:
		level = stats.level
	
	if "exp" in stats:
		stat_list.get_node("EXPValue").text = str(stats.exp)
		stat_list.get_node("NEXTValue").text = str(Com.exp_for_level(level) - stats.exp + Com.total_exp_for_level(level-1))

func on_press_key(key):
	pass