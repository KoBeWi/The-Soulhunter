extends KinematicBody2D

var controls = {}
var key_press = {}

var initiated = false
var changeroomed = false
var uname = ""
var motion = Vector2()
#var enemies = []
var id = -1

var on_floor = false
var attack = false

onready var sprite = $Sprite
onready var chr = $Character
onready var anim = $Animation
onready var mapid = $"../../Map".mapid

func _ready():
	add_to_group("players")
	$Sprite/ArmPosition.visible = false

func initialize(n):
	uname = n[0]
	if n[1] != -1: id = n[1]
	
	$Name.set_text("<" + uname + ">")
	Com.controls.register_player(self)
	anim.play("Idle")

func _physics_process(delta):
	var flip = sprite.flip_h
	
	motion += Vector2(0, 1)
	if controls.has("RIGHT"):
		motion.x = 8
		sprite.flip_h = false
	elif controls.has("LEFT"):
		motion.x = -8
		sprite.flip_h = true
	else:
		motion.x = 0
	
	if motion.y > 2: on_floor = false
	
	if flip != sprite.flip_h: flip()
		
	if key_press.has("JUMP") and on_floor:
		motion.y = -20
	
	if attack:
		pass
	elif motion.y < 0:
		on_floor = false
		if anim.assigned_animation != "Jump":
			anim.play("Jump")
	elif !on_floor and motion.y >= 0:
		if anim.assigned_animation != "Fall":
			anim.play("Fall")
	elif motion.x != 0:
		anim.current_animation = "Walk"
	else:
		anim.play("Idle")
	
	var collided = move_and_collide (Vector2(0, motion.y))
	if collided:
		if motion.y > 0:
			on_floor = true
		motion.y = 0
	collided = move_and_collide (Vector2(motion.x, 0))
	
	if collided and collided.normal.y < 0:
		move_and_collide(motion.slide(collided.normal))
	
	if key_press.has("ATTACK") and !attack:
		attack = true
		$Sprite/ArmPosition.visible = true
		anim.playback_speed = 4
		anim.play("SwingAttack1" + direction())
	
	key_press.clear()

func set_pos_and_broadcast(pos):
	pos = Vector2(int(pos.x), int(pos.y))
	position = pos
	
	Network.send_data(["POS", int(pos.x), int(pos.y), direction()])

func press_key(uname):
	controls[uname] = true
	key_press[uname] = true

func release_key(uname):
	controls.erase(uname)

func flip(f = $Sprite.flip_h):
	$Sprite.flip_h = f
	var oldpos = $Sprite/ArmPosition.position
	$Sprite/ArmPosition.position = Vector2(-oldpos.x, oldpos.y)
	

func direction():
	if sprite.flip_h:
		return "L"
	else:
		return "R"

func damage(amount):
	chr.hp -= amount

func attack_end():
	attack = false
	$Sprite/ArmPosition.visible = false
	anim.playback_speed = 8

func weapon_enter(body):
	if !attack: return
	
	if Com.server and body.is_in_group ("enemies"):
		Network.send_data(["DAMAGE", mapid, "p", id, body.id, "N"])
		#enemies.append(body.get_name())

func weapon_exit(body):
	return
#	if self == Com.player and body.get("is_enemy"):
#		enemies.erase(body.get_name())