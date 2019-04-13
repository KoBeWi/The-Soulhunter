extends StaticBody2D

export(Resource) var data

func attack():
	return {damage = data.attack} 