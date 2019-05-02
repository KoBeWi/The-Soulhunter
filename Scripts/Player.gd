extends KinematicBody2D

const GRAVITY = 100
const SPEED = 500
const JUMP = 1500

var controls = {}
var key_press = {}

var uname = "" setget set_username
var motion = Vector2()
var last_server_position = Vector2()
var main = false

var stats
var last_exp = -1
var last_level = -1
#var enemies = []

var last_tick = 0
var last_controls = 0
var desync = 0

var jump = false
var attack = false

onready var sprite = $Sprite
onready var arm = $Sprite/ArmPosition
onready var weapon_point = $Sprite/ArmPosition/Arm/WeaponHinge
onready var chr = $Character
onready var anim = $Animation

var camera

signal initiated

func _ready():
	if Com.register_node(self, "Player"): return
	set_weapon(preload("res://Nodes/Weapons/0.tscn").instance())
	
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
	set_physics_process(false)

func on_initialized():
	visible = true
	set_process(true)
	set_physics_process(true)
	emit_signal("initiated")

func _process(delta):
	if sprite.position.length_squared() > 1:
		sprite.position *= 0.8
	else:
		sprite.position = Vector2()
	
	if camera:
		camera.position = sprite.position

func _physics_process(delta):
	var flip = sprite.flip_h
	
	motion += Vector2(0, GRAVITY)
	if controls.has(Controls.RIGHT):
		motion.x = SPEED
		sprite.flip_h = false
	elif controls.has(Controls.LEFT):
		motion.x = -SPEED
		sprite.flip_h = true
	else:
		motion.x = 0
	
	if flip != sprite.flip_h: flip()
		
	if key_press.has(Controls.JUMP) and is_on_floor():
		jump = true
		motion.y = -JUMP
	
	if attack:
		pass
	elif motion.y < 0:
		if anim.assigned_animation != "Jump":
			anim.play("Jump")
	elif !is_on_floor() and motion.y >= 0:
		jump = false
		
		if anim.assigned_animation != "Fall":
			anim.play("Fall")
	elif motion.x != 0:
		anim.current_animation = "Walk"
	else:
		anim.play("Idle")
	
	motion = move_and_slide_with_snap(motion, Vector2.DOWN * 32 if !jump else Vector2(), Vector2.UP, true)
	
	if key_press.has(Controls.ATTACK) and !attack:
		attack = true
		arm.visible = true
		anim.playback_speed = 4
		anim.play("SwingAttack1" + direction())
	
	if !controls.empty():
		last_controls = last_tick
	key_press.clear()

func on_key_press(p_id, key, state):
	if (!main or state == Controls.State.ACTION) and p_id == get_meta("id"):
		controls[key] = true
		key_press[key] = true

func on_key_release(p_id, key, state):
	if (!main or state == Controls.State.ACTION) and p_id == get_meta("id"):
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
	main = true
	
	camera = preload("res://Nodes/PlayerCamera.tscn").instance()
	camera.make_current()
	add_child(camera)
	
	Network.connect("stats", self, "on_stats")
	
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

func apply_state_vector(timestamp, diff_vector, vector):
	if vector[0] != uname:
		self.uname = vector[0]
	
	var target_position = Vector2(vector[1], vector[2])
	last_tick = timestamp
	
	if !main or Com.time_greater(timestamp, last_controls + 5):
		desync = 0
		var old_position = position
		
		if old_position.round() != target_position:
			position = target_position
		elif last_server_position != Vector2():
			position = last_server_position
		
		if has_meta("initialized"): sprite.position += (old_position - position)
	else:
		if (last_server_position - position).length_squared() > 10000:
			desync += 1
			
			if desync == 10:
				position = target_position
				desync = 0
	
	if (diff_vector & 2) > 0:
		last_server_position.x = vector[1]
	if (diff_vector & 4) > 0:
		last_server_position.y = vector[2]

func on_hit(body):
	pass # Replace with function body.

func on_unhit(body):
	pass # Replace with function body.

func check_map(map):
	if position.x >= map.width * 1920:
		return 1
	elif position.x < 0:
		return 3
	
	return 4

func update_camera():
	camera.limit_right = Com.game.map.width * 1920
	camera.limit_bottom = Com.game.map.height * 1080

func set_weapon(weapon):
	if weapon_point.get_child_count() > 0:
		weapon_point.get_chil(0).queue_free()
	
	weapon.player = self
	weapon_point.add_child(weapon)

func on_stats(stats):
	if "level" in stats:
		if last_exp > -1 and stats.exp > last_exp:
			preload("res://Nodes/Effects/PopupText.tscn").instance().start(self, "Level Up!", Color(1, 1, 0.5))
		last_exp = stats.exp
	
	if "exp" in stats:
		if last_exp > -1 and stats.exp > last_exp:
			preload("res://Nodes/Effects/PopupText.tscn").instance().start(self, str("EXP +", stats.exp - last_exp), Color.yellow)
		last_exp = stats.exp

func set_stats(_stats):
	stats = parse_json("{" + _stats.right(_stats.find('"name"')))