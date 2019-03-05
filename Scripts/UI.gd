extends CanvasLayer

onready var chr = Com.player.get_node("Character")

func _ready():
	get_parent().UI = self

func _process(delta):
	update_bar("HP")
	update_bar("MP")
	$"HUD/Lv Label".text = str(chr.level)
	$"HUD/Exp Bar".max_value = exp_for_level(chr.level)
	$"HUD/Exp Bar".value = chr.experience - total_exp_for_level(chr.level-1)

func update_bar(name):
	var bar = get_node("HUD/" + name + " Bar")
	var label = get_node("HUD/" + name + " Label")
	
	bar.set_max(chr.get("max_" + name.to_lower()))
	bar.set_value(chr.get(name.to_lower()))
	
	label.set_text(str(bar.get_value()) + "/" + str(bar.get_max()))
	if bar.get_value() < bar.get_max() / 8:
		label.set("custom_colors/font_color", Color(1,0,0))
	elif bar.get_value() < bar.get_max() / 4:
		label.set("custom_colors/font_color", Color(1,1,0))
	else:
		label.set("custom_colors/font_color", Color(1,1,1))

func exp_for_level(level):
	return level * 10
	
func total_exp_for_level(level):
	return level * (level + 1) * 5