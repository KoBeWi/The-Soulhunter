tool
extends Area2D

export var location = "World"
export var mapid = -1
export var map_x = 0
export var map_y = 0
export var width = 0
export var height = 0

export var borders = []

func _ready():
	if !Engine.editor_hint:
		var shape_node = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.extents = Vector2(width * 1920, height * 1080)
		shape_node.shape = shape
		add_child(shape_node)

func _draw():
	if Engine.editor_hint:
		for x in width:
			for y in height:
				draw_line(Vector2(x * 1920, (y + 1) * 1080), Vector2((x + 1) * 1920, (y + 1) * 1080), Color.white)
				draw_line(Vector2((x + 1) * 1920, y * 1080), Vector2((x + 1) * 1920, (y + 1) * 1080), Color.white)

func on_exit(body):
	if body.has_method("_dispose"):
		body.call("_dispose")