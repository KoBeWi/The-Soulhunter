extends StaticBody2D
class_name Weapon

export(String) var weapon_name
var data
var player

func _ready():
	data = Res.items[weapon_name]

func attack():
#	return {damage = data.attack + player.stats.attack}
	return {damage = player.stats.attack}

func set_disabled(disabled):
	$Shape.disabled = disabled