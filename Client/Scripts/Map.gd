extends Control

onready var middle = load("res://Graphics/Map/Room.png")
onready var wall = load("res://Graphics/Map/Wall.png")
onready var way = load("res://Graphics/Map/Way.png")
onready var corner = load("res://Graphics/Map/Corner.png")
onready var edge = load("res://Graphics/Map/Edge.png")

onready var chr = get_node("../../../Character")

var cam_x = 10
var cam_y = 10

func _draw():
	for map in Res.maps:
		map = map.instance()
		for dx in range(map.width):
			for dy in range(map.height):
				var x = map.map_x + dx
				var y = map.map_y + dy
				
				if get_hole(map, dx, dy) or !chr.map.has([x, y]): continue
				draw_room(x, y, get_border(map, dx, dy, 0), get_border(map, dx, dy, 1), get_border(map, dx, dy, 2), get_border(map, dx, dy, 3),
					get_edge(map, dx, dy, 0), get_edge(map, dx, dy, 1), get_edge(map, dx, dy, 2), get_edge(map, dx, dy, 3))

func get_border(source, x, y, dir):
	return source.borders[(x + y * source.width)*4 + dir]

func get_edge(source, x, y, dir):
	return source.edges[(x + y * source.width)*4 + dir]

func get_hole(source, x, y):
	return source.holes[x + y * source.width]

func draw_room(x, y, u_border, r_border, d_border, l_border, dl_edge, ul_edge, ur_edge, dr_edge):
	x -= 32768 - cam_x
	y -= 32768 - cam_y
	
	draw_set_transform(Vector2(x * 30, y * 30), 0, Vector2(1, 1))
	draw_texture(middle, Vector2(), Color(0, 0.5, 0))
	if u_border > 0:
		draw_texture(wall if u_border == 1 else way, Vector2(), Color(1, 0.8, 0))
	if u_border > 0 and l_border > 0:
		draw_texture(corner, Vector2(), Color(1, 0.8, 0))
	if dl_edge:
		draw_texture(edge, Vector2(), Color(1, 0.8, 0))
	
	draw_set_transform(Vector2((x+1) * 30, y * 30), PI/2, Vector2(1, 1))
	if r_border > 0:
		draw_texture(wall if r_border == 1 else way, Vector2(), Color(1, 0.8, 0))
	if u_border > 0 and r_border > 0:
		draw_texture(corner, Vector2(), Color(1, 0.8, 0))
	if ul_edge:
		draw_texture(edge, Vector2(), Color(1, 0.8, 0))
	
	draw_set_transform(Vector2((x+1) * 30, (y+1) * 30), PI, Vector2(1, 1))
	if d_border > 0:
		draw_texture(wall if d_border == 1 else way, Vector2(), Color(1, 0.8, 0))
	if d_border > 0 and r_border > 0:
		draw_texture(corner, Vector2(), Color(1, 0.8, 0))
	if ur_edge:
		draw_texture(edge, Vector2(), Color(1, 0.8, 0))
	
	draw_set_transform(Vector2(x * 30, (y+1) * 30), 3*PI/2, Vector2(1, 1))
	if l_border > 0:
		draw_texture(wall if l_border == 1 else way, Vector2(), Color(1, 0.8, 0))
	if d_border > 0 and l_border > 0:
		draw_texture(corner, Vector2(), Color(1, 0.8, 0))
	if dr_edge:
		draw_texture(edge, Vector2(), Color(1, 0.8, 0))

func set_room(room):
	$Position.position = Vector2((room[0] - 32768 + cam_x) * 30 + 15, (room[1] - 32768 + cam_x) * 30 + 15)