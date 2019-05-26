class_name Soul
extends Sprite

const TYPE_COLOR = {
	"trigger": Color(1, 0, 0),
	"active": Color(0, 0, 1),
	"augment": Color(1, 1, 0),
	"ability": Color(0, 1, 0),
	"enchant": Color(1, 0, 1),
	"extension": Color(1, 1, 1, 0.5),
	"catalyst": Color(0, 1, 1),
	"mastery": Color(0, 0, 0),
	"identity": Color(1, 1, 1)
	}
const SPEED = 24
const SPEED_SQ = SPEED * SPEED

var direction
var soul setget set_id
var timeout = false
var dir = 0
var player_id
var target_player

func _ready():
	if Com.register_node(self, "Effects/Soul", true): return
	$Timer.connect("timeout", self, "set", ["timeout", true])

func _physics_process(delta):
	if !target_player:
		target_player = Com.game.get_entity(player_id)
		if !target_player:
			queue_free()
			print("invalid player: ", player_id)
			return
	
	if !direction:
		direction = (global_position - target_player.global_position).angle()
	
	var move = Vector2(cos(direction), sin(direction))
	position += move * SPEED
	
	if !timeout:
		return
	
	var target = target_player.global_position - global_position
	var angle_to_target = move.angle_to(target)
	if dir == 0:
		dir = sign(angle_to_target)
	
	if abs(angle_to_target) > 0.2: direction += abs(angle_to_target)/4 * dir
	
	if global_position.distance_squared_to(target_player.global_position) < SPEED_SQ:
		queue_free()

func set_id(id):
	soul = id
	modulate = TYPE_COLOR[Res.souls[id].type]

func state_vector_types():
	return [
			Data.TYPE.U16,
			Data.TYPE.U16,
			Data.TYPE.U16,
			Data.TYPE.U16
		]

func get_state_vector():
	return [
			TYPE_COLOR.keys().find(Res.souls[soul].type) if soul else -1,
			round(position.x),
			round(position.y),
			player_id
		]

func apply_state_vector(timestamp, diff_vector, vector):
	modulate = TYPE_COLOR[TYPE_COLOR.keys()[vector[0]]]
	position = Vector2(vector[1], vector[2])
	player_id = vector[3]