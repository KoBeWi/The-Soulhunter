extends KinematicBody2D

var controls = {}
var key_press = {}

var initiated = false
var changeroomed = false
var uname = "" setget set_username
var motion = Vector2()
var smooth_position = Vector2()
#var enemies = []

var on_floor = false
var attack = false

onready var sprite = $Sprite
onready var arm = $Sprite/ArmPosition
onready var chr = $Character
onready var anim = $Animation

var camera

signal initiated

func _ready():
	if Com.register_node(self, "Player"): return
	
	Com.controls.connect("key_press", self, "on_key_press")
	Com.controls.connect("key_release", self, "on_key_release")
	arm.visible = false

func set_username(n):
	uname = n
	$Name.text = "<" + uname + ">"
#	anim.play("Idle")

func on_client_create():
	visible = false
	set_process(false)

func on_initialized():
	set_process(true)
	visible = true
	emit_signal("initiated")

func _process(delta):
	if sprite.position.length_squared() > 1:
		sprite.position *= 0.8
	else:
		sprite.position = Vector2()

func _physics_process(delta):
	var flip = sprite.flip_h
	
	motion += Vector2(0, 1)
	if controls.has(Controls.RIGHT):
		motion.x = 8
		sprite.flip_h = false
	elif controls.has(Controls.LEFT):
		motion.x = -8
		sprite.flip_h = true
	else:
		motion.x = 0
	
	if motion.y > 2: on_floor = false
	
	if flip != sprite.flip_h: flip()
		
	if key_press.has(Controls.JUMP) and on_floor:
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
	
	if key_press.has(Controls.ATTACK) and !attack:
		attack = true
		arm.visible = true
		anim.playback_speed = 4
		anim.play("SwingAttack1" + direction())
	
	key_press.clear()

func on_key_press(p_id, key):
	if p_id == get_meta("id"):
		controls[key] = true
		key_press[key] = true

func on_key_release(p_id, key):
	if p_id == get_meta("id"):
		controls.erase(key)

func flip(f = sprite.flip_h):
	sprite.flip_h = f
	var oldpos = arm.position
	arm.position = Vector2(-oldpos.x, oldpos.y)
	

func direction():
	if sprite.flip_h:
		return "L"
	else:
		return "R"

func damage(amount):
	chr.hp -= amount

func attack_end():
	attack = false
	arm.visible = false
	anim.playback_speed = 8

func weapon_enter(body):
	if !attack: return
	
#	if Com.server and body.is_in_group ("enemies"):
#		Network.send_data(["DAMAGE", "mapid", "p", id, body.id, "N"])
		#enemies.append(body.get_name())

func weapon_exit(body):
	return
#	if self == Com.player and body.get("is_enemy"):
#		enemies.erase(body.get_name())

func set_main():
	Com.player = self
	$Name.visible = false
	
	camera = preload("res://Nodes/PlayerCamera.tscn").instance()
	camera.make_current()
	add_child(camera)
	
	Com.controls.set_master(self)

func state_vector_types():
	return [
			Data.TYPE.STRING,
			Data.TYPE.U16,
			Data.TYPE.U16
		]

func get_state_vector():
	return [
			uname,
			round(position.x),
			round(position.y)
		]

func apply_state_vector(vector):
	self.uname = vector[0]
	
	var old_position = position
	position.x = vector[1]
	position.y = vector[2]
	if get_meta("initialized"): sprite.position = (old_position - position) + sprite.position