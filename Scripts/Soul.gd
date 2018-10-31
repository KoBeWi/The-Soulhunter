extends Sprite

const type_color = {"trigger": Color(1, 0, 0), "active": Color(0, 0, 1), "augment": Color(1, 1, 0), "ability": Color(0, 1, 0),
"enchant": Color(1, 0, 1), "catalyst": Color(0, 1, 1), "extension": Color(1, 1, 1, 0.5), "mastery": Color(0, 0, 0),
"identity": Color(1, 1, 1)}
const speed = 24
var direction = 0
var soul
var timer = 10
var dir = 0

func _ready():
	set_process(true)

func _physics_process(delta):
	timer -= 1
	var move = Vector2(sin(direction), cos(direction))
	translate(move * speed)
	if timer > 0: return
	
	var target = Com.player.global_position - global_position
	var angle_to_target = move.angle_to(target)
	if dir == 0:
		dir = sign(angle_to_target)
	
	if abs(angle_to_target) > 0.2: direction += abs(angle_to_target)/6 * dir
	
	if global_position.distance_to(Com.player.global_position) < speed*2:
		Com.game.got_soul(soul)
		queue_free()

func set_id(i):
	soul = Res.souls[i]
	set_modulate(type_color[soul["type"]])
	direction = (global_position - Com.player.global_position).angle()