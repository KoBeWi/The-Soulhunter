extends StaticBody2D

export(String) var weapon_name
var data
var player

func _ready():
	data = Res.items[weapon_name]

func attack():
	return {damage = data.attack + player.stats.attack}