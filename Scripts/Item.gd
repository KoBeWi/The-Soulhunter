extends KinematicBody2D

var id = 0
var gravity = Vector2()

func _ready():
	pass

func _physics_process(delta):
	gravity.y += 1
	move_and_collide(gravity)

func set_id(id):
	self.id = id
	get_node("Sprite").texture = load("res://Graphics/Items/" + str(id) + ".png")

func _body_enter(body):
	if body.is_in_group("players"):
		if Com.server:
			Network.send_data(["GOTITEM", body.mapid, body.id, id])
		queue_free()