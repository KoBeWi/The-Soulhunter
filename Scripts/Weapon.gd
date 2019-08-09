extends StaticBody2D
class_name Weapon

export(String) var weapon_name
export(String) var attack_type
export var speed = 16

var data
var player

func _ready():
	if weapon_name != "":
		data = Res.items[weapon_name]
	else:
		data = {attack = 1}

func attack():
	return {damage = player.stats.attack}

func set_disabled(disabled):
	$Shape.disabled = disabled