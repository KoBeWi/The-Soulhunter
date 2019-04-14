extends StaticBody2D

export var id = 0
var data

func _ready():
	data = Res.items[id]

func attack():
	return {damage = data.attack} 