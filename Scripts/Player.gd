extends KinematicBody2D

const GRAVITY = 100
const SPEED = 500
const JUMP = 1500

enum ACTIONS{NONE, SKELETON}

var controls = {}
var key_press = {}

var uname = "" setget set_username
var motion = Vector2()
var last_server_position = Vector2()
var main = false
var action = ACTIONS.NONE
var cached_action = ACTIONS.NONE

var jump = false
var attack = false
var skeleton = false

var stats
var last_exp = -1
var last_level = -1
var equipment
var souls

var last_tick = 0
var last_controls = 0
var desync = 0
var newest_enemy = null

onready var sprite = $Sprite
onready var arm = $Sprite/ArmPosition
onready var weapon_point = $Sprite/ArmPosition/Arm/WeaponHinge
onready var chr = $Character
onready var anim = $Animation

var camera

signal initiated
signal reg_mp
signal damaged

func _ready():
	if Com.register_node(self, "Player"): return
	
	Com.controls.connect("key_press", self, "on_key_press")
	Com.controls.connect("key_release", self, "on_key_release")
	arm.visible = false

func set_username(n):
	uname = n
	$Name.text = "<" + uname + ">"
#	anim.play("Idle")

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
	
	if action != ACTIONS.NONE:
		cached_action = action
	
	match action:
		ACTIONS.SKELETON:
			if skeleton:
				sprite.visible = true
				$Skeleton.visible = false
			else:
				sprite.visible = false
				$Skeleton.visible = true
			skeleton = !skeleton
			
			action = ACTIONS.NONE

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
		if skeleton:
			pass
		else:
			if controls.has(Controls.UP):
				trigger_soul()
			else:
				if get_weapon():
					get_weapon().set_disabled(false)
					attack = true
					arm.visible = true
					anim.playback_speed = 4
					anim.play("SwingAttack1" + direction())
			
	elif key_press.has(Controls.SOUL) and !attack:
		active_soul()
	
	if !controls.empty():
		last_controls = last_tick
	key_press.clear()

func trigger_soul():
	if !Com.is_server: return ##TODO: klient może dostawać info
	
	var soul
	if souls[0] > 0:
		soul = Res.get_res(Res.souls, souls[0])
	
	if soul:
		if "mp" in soul:
			if stats.mp < soul.mp: return
			stats.mp -= soul.mp
		
		get_meta("character").call("SyncStat", "mp", stats.mp)
		
		match int(souls[0]):
			1:
				var bone = preload("res://Nodes/Projectiles/PBone.tscn").instance()
				get_parent().add_child(bone)
				bone.position = position + Vector2(0, -80)
				bone.velocity.x = abs(bone.velocity.x) * direction_i()
				bone.player = self

func active_soul():
	if !Com.is_server: return ##TODO: klient może dostawać info
	
	var soul
	if souls[1] > 0:
		soul = Res.get_res(Res.souls, souls[1])
	
	if soul:
		if "mp" in soul:
			if stats.mp < soul.mp: return
			stats.mp -= soul.mp
		
		get_meta("character").call("SyncStat", "mp", stats.mp)
		
		match int(souls[1]):
			2:
				action = ACTIONS.SKELETON
	

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

func direction_i():
	if sprite.flip_h:
		return -1
	else:
		return 1

func damage(enemy):
	if Com.is_server:
		var damage = enemy.attack
		stats.hp = max(0, stats.hp - damage)
		get_meta("room").call("Damage", get_meta("id"), damage)

func attack_end():
	attack = false
	arm.visible = false
	anim.playback_speed = 8
	get_weapon().set_disabled(true)

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
	Network.connect("equipment", self, "on_eq")
	
	Com.controls.set_master(self)

func on_hit(body):
	if body.is_in_group("enemies"):
		newest_enemy = body
		damage(newest_enemy)
		$Invincibility.start()

func on_unhit(body):
	if body == newest_enemy:
		newest_enemy = null

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
		weapon_point.get_child(0).queue_free()
	
	if weapon > 0:
		var weap = load(str("res://Nodes/Weapons/", Res.get_res(Res.items, weapon).name ,".tscn")).instance()
		weap.player = self
		weap.set_disabled(true)
		weapon_point.add_child(weap)

func get_weapon() -> Weapon:
	if weapon_point.get_child_count() == 0:
		return null
	
	return weapon_point.get_child(0)

func on_stats(stats):
	if "level" in stats:
		if last_exp > -1 and stats.exp > last_exp:
			preload("res://Nodes/Effects/PopupText.tscn").instance().start(self, "Level Up!", Color(1, 1, 0.5))
		last_exp = stats.exp
	
	if "exp" in stats:
		if last_exp > -1 and stats.exp > last_exp:
			preload("res://Nodes/Effects/PopupText.tscn").instance().start(self, str("EXP +", stats.exp - last_exp), Color.yellow)
		last_exp = stats.exp

func on_eq(eq):
	set_weapon(eq[0])

func set_stats(_stats):
	stats = parse_json(_stats)

func set_equipment(eq):
	equipment = parse_json(eq)
	
	if equipment[0]:
		set_weapon(int(equipment[0]))

func set_souls(suls):
	souls = parse_json(suls)

func reg_mp():
	if Com.is_server:
		stats.mp = min(stats.mp + 1, stats.max_mp)
	else:
		emit_signal("reg_mp")


func on_not_invincible():
	if newest_enemy:
		damage(newest_enemy)

func _on_damage(amount):
	emit_signal("damaged", amount)

func state_vector_types():
	return [
			Data.TYPE.STRING,
			Data.TYPE.U16,
			Data.TYPE.U16,
			Data.TYPE.U8
		]

func get_state_vector():
	set_deferred("cached_action", ACTIONS.NONE)
	
	return [
			uname,
			round(position.x),
			round(position.y),
			int(cached_action)
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
	
	action = vector[3]