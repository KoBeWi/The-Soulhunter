tool
extends Node2D

export var location = "World"
export var mapid = -1
export var map_x = 0
export var map_y = 0
export var width = 0
export var height = 0

export var borders = []
export var edges = []
export var holes = []

func _draw():
	if Engine.editor_hint:
		for x in width:
			for y in height:
				draw_line(Vector2(x * 1920, (y + 1) * 1080), Vector2((x + 1) * 1920, (y + 1) * 1080), Color.white)
				draw_line(Vector2((x + 1) * 1920, y * 1080), Vector2((x + 1) * 1920, (y + 1) * 1080), Color.white)