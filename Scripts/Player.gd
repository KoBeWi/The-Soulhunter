class_name Player
extends KinematicBody2D

const GRAVITY = 100
const SPEED = 500
const JUMP = 1500

enum ACTIONS {NONE, SKELETON, HOVER}
enum ABILITIES {
	AUTO_JUMP,
	DOUBLE_JUMP
}

var controls = {}
var key_press = {}
var key_release = {}

var main = false
var uname = "" setget set_username
var hue = 0
var motion = Vector2()
#var last_server_position = Vector2()
var last_room

var action = ACTIONS.NONE
var cached_action = ACTIONS.NONE
var prev_action = ACTIONS.NONE

var weapon_id = 0
var animation = "Idle"
var cooldown = false

var crouch = false
var jump = false
var double_jump = false
var attack = false

var stats
var last_exp = -1
var last_level = -1
var equipment
var souls
var abilities = [false, false] #zdehardkodować

var last_tick = 0
var last_controls = -100
var desync = 0
var newest_enemy = null
var interactable

onready var sprite = $Sprite
onready var sprite2 = $Sprite/Sprite
onready var sprite3 = $Skeleton
onready var weapon_point = $Sprite/WeaponHinge
onready var chr = $Character
onready var anim = $Animation
onready var hitbox = $Hitbox
onready var trigger_timer = $TriggerTimer
onready var active_timer = $ActiveTimer
onready var invincibility = $Invincibility

var camera

signal initiated
signal reg_mp
signal room_changed(room)

func _ready():
	if Com.register_node(self, "Player"): return
	
	Com.controls.connect("key_press", self, "on_key_press")
	Com.controls.connect("key_release", self, "on_key_release")
	weapon_point.visible = false
	
	set_weapon(weapon_id)

func set_username(n):
	uname = n
	$Name.text = "<" + uname + ">"

func on_initialized():
	visible = true
	set_process(true)
	set_physics_process(true)
	emit_signal("initiated")

func _process(delta):
	if !Com.is_server: process_sprite()
	process_rooms()

func process_sprite():
	if sprite.position.length_squared() > 1:
		sprite.position *= 0.8
	else:
		sprite.position = Vector2()

	if camera:
		camera.position = sprite.position

func process_rooms():
	var room
	if Com.is_server:
	 	room = Vector2(get_meta("map").map_x + int(position.x)/1920, get_meta("map").map_y + int(position.y)/1080)
	elif Com.game.map:
		room = Vector2(Com.game.map.map_x + int(position.x)/1920, Com.game.map.map_y + int(position.y)/1080)
	
	if room and room != last_room:
		last_room = room
		
		if Com.is_server:
			get_meta("room").DiscoverRoom(get_meta("id"), room)
		else:
			emit_signal("room_changed", room)
	
func process_actions():
	if action != ACTIONS.NONE:
		cached_action = action
	
	match action:
		ACTIONS.NONE:
			if prev_action == ACTIONS.SKELETON:
				sprite.visible = true
				sprite3.visible = false
		ACTIONS.SKELETON:
			if prev_action == ACTIONS.NONE:
				sprite.visible = false
				sprite3.visible = true
		
		ACTIONS.HOVER:
			if prev_action == ACTIONS.NONE:
				active_timer.start(2)
				motion.y = 0
				jump = true
				double_jump = true
	
	prev_action = action

func _physics_process(delta):
	if action != ACTIONS.HOVER:
		motion += Vector2(0, GRAVITY)
	
	process_walking()
	process_crouching()
	process_jumping()
	process_attack()
	if !Com.is_server: process_animations()
	
	motion = move_and_slide_with_snap(motion, Vector2.DOWN * 32 if !jump else Vector2(), Vector2.UP, true)
	
	process_controls()
	process_actions()

func process_walking():
	var flip = sprite.flip_h
	var not_move = crouch or action == ACTIONS.HOVER
	
	if Controls.RIGHT in controls:
		if !not_move: motion.x = SPEED
		sprite.flip_h = false
	elif Controls.LEFT in controls:
		if !not_move: motion.x = -SPEED
		sprite.flip_h = true
	else:
		not_move = true
	
	if not_move:
		motion.x = 0
	
	if flip != sprite.flip_h: flip()

func process_crouching():
	if is_on_floor() and Controls.DOWN in key_press:
		crouch = true
		hitbox.get_child(0).disabled = true
		hitbox.get_child(1).disabled = false
	elif crouch and Controls.DOWN in key_release:
		crouch = false
		hitbox.get_child(0).disabled = false
		hitbox.get_child(1).disabled = true

func process_jumping():
	if is_on_floor():
		jump = false
		double_jump = false
	
	if (is_on_floor() or (abilities[ABILITIES.DOUBLE_JUMP] and not double_jump)) and ((abilities[ABILITIES.AUTO_JUMP] and !jump and Controls.JUMP in controls) or Controls.JUMP in key_press):
		if !jump:
			jump = true
		else:
			double_jump = true
		motion.y = -JUMP

func process_animations():
	var prev_anim = animation
	
	if action != ACTIONS.SKELETON:
		if attack:
			pass
		elif !is_on_floor() and jump:
			animation = "Jump"
		elif !is_on_floor() and !jump:
			animation = "Fall"
		elif crouch:
			animation = "Crouch"
		elif motion.x != 0:
			animation = "Walk"
		else:
			animation = "Idle"
	else:
		if attack:
			pass
		elif motion.x != 0:
			animation = "SkeletonWalk"
		else:
			animation = "SkeletonStand"
	
	if animation != prev_anim:
		anim.play(animation)
		if animation == "Crouch" and prev_anim != "Idle":
			anim.advance(2)

func process_attack():
	if attack: return
	
	if Controls.ATTACK in key_press:
		if action == ACTIONS.SKELETON:
			anim.play("SkeletonAttack")
			if Com.is_server and souls[0] == 5:
				trigger_soul({free = true})
		else:
			if Controls.UP in controls:
				trigger_soul()
			else:
				if get_weapon():
					get_weapon().set_disabled(false)
					attack = true
					weapon_point.visible = true
					anim.playback_speed = 16
					animation = str(get_weapon().attack_type, "Attack", "Crouch" if crouch else "", direction())
					anim.play(animation)
	elif Controls.SOUL in key_press:
		active_soul(true)
	elif Controls.SOUL in key_release:
		active_soul(false)

func process_controls():
	if interactable and Controls.UP in key_press:
		interactable.interact(self)
	
	if Controls.LEFT in controls or Controls.RIGHT in controls:
		last_controls = last_tick
	key_press.clear()
	key_release.clear()

func trigger_soul(ops = {}):
	if !Com.is_server: return ##TODO: klient może dostawać info
	
	var soul
	if souls[0] > 0:
		soul = Res.get_res(Res.souls, souls[0])
	
		if use_soul(soul):
			if "mp" in soul and not "free" in ops:
				stats.mp -= soul.mp
				get_meta("character").SyncStat("mp", stats.mp)

func use_soul(soul):
	if "mp" in soul:
		if stats.mp < soul.mp: return
	
	match soul.name:
		"Summon Bat":
			var bat = preload("res://Nodes/Projectiles/PBat.tscn").instance()
			get_parent().add_child(bat)
			bat.position = position
			if Com.is_server:
				bat.home(direction_i())
			bat.player = self
		
		"Echo of Bat":
			var echo = preload("res://Nodes/Projectiles/PEcho.tscn").instance()
			get_parent().add_child(echo)
			echo.position = position
			echo.player = self
		
		"Bone Throw":
			if cooldown: return
			
			var bone = preload("res://Nodes/Projectiles/PBone.tscn").instance()
			get_parent().add_child(bone)
			bone.position = position + Vector2(0, -60)
			if souls[4] == 9:
				cooldown(0.25)
				bone.velocity.x = abs(bone.velocity.x) * direction_i() * (1 + randf())
				bone.velocity.y *= 1.5
				bone.powered = true
			else:
				cooldown(0.75)
				bone.velocity.x = abs(bone.velocity.x) * direction_i()
			bone.player = self
		
		"Dagger Throw":
			var dagger = preload("res://Nodes/Projectiles/PDagger.tscn").instance()
			get_parent().add_child(dagger)
			dagger.position = position
			dagger.velocity.x = abs(dagger.velocity.x) * direction_i()
			dagger.player = self
		
		"Summon Skeleton":
			var skeleton = preload("res://Nodes/Projectiles/PSkeleton.tscn").instance()
			get_parent().add_child(skeleton)
			skeleton.position = position
			skeleton.velocity.x = abs(skeleton.velocity.x) * direction_i()
			skeleton.player = self
		
	return true

func cooldown(s):
	cooldown = true
	trigger_timer.start(s)

func active_soul(pressed):
	if !Com.is_server: return ##TODO: klient może dostawać info
	
	var soul
	if souls[1] > 0:
		soul = Res.get_res(Res.souls, souls[1])
	
	if soul:
		if "mp" in soul:
			if stats.mp < soul.mp: return
			stats.mp -= soul.mp
		
		get_meta("character").SyncStat("mp", stats.mp)
		
		match int(souls[1]):
			4:
				if pressed:
					if !is_on_floor() and !double_jump:
						action = ACTIONS.HOVER
				else:
					action = ACTIONS.NONE
			6:
				if pressed:
					action = ACTIONS.SKELETON if action == ACTIONS.NONE else ACTIONS.NONE
	

func on_key_press(p_id, key, state):
	if (!main or state == Controls.State.ACTION) and p_id == get_meta("id"):
		controls[key] = true
		key_press[key] = true

func on_key_release(p_id, key, state):
	if p_id == get_meta("id"):
		if main and state != Controls.State.ACTION and key in controls:
			Packet.new(Packet.TYPE.KEY_RELEASE).add_u8(key).send()
		
		controls.erase(key)
		key_release[key] = true

func flip(f = sprite.flip_h):
	sprite.flip_h = f
	sprite2.flip_h = f
	sprite3.flip_h = !f

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
		get_meta("room").Damage(get_meta("id"), damage)
		
		if stats.hp <= 0:
			get_meta("room").GameOver(get_meta("id"))
		else:
			get_meta("room").PlayerDamaged(get_meta("id"), stats.hp)

func attack_end():
	attack = false
	if action == ACTIONS.SKELETON:
		anim.play("SkeletonStand")
	else:
		weapon_point.visible = false
		anim.playback_speed = 8
		get_weapon().set_disabled(true)

func set_main():
	Com.player = self
	$Name.visible = false
	main = true
	
	camera = preload("res://Nodes/PlayerCamera.tscn").instance()
	camera.make_current()
	add_child(camera)
	
	Network.connect("stats", self, "on_stats")
	Network.connect("equipment", self, "on_eq")
	Network.connect("abilities", self, "set_abilities")
	Network.connect("saved", self, "on_save")

func on_hit(body):
	if body.is_in_group("enemies"):
		newest_enemy = body
		damage(newest_enemy)
		invincibility.start()

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
	weapon_id = weapon
	if weapon_point.get_child_count() > 0:
		weapon_point.get_child(0).queue_free()
	
	var weap = preload("res://Nodes/Weapons/Fist.tscn")
	if weapon > 0:
		weap = load(str("res://Nodes/Weapons/", Res.get_res(Res.items, weapon).name ,".tscn")).instance()
	else:
		weap = weap.instance()
	
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

func set_interactable(node):
	interactable = node
	if !Com.is_server and main:
		$PressUp.visible = true
		$PressUp/Animation.play("Idle")

func reset_interactable(node):
	if interactable == node:
		interactable = null
		if !Com.is_server and main:
			$PressUp.visible = false

func state_vector_types():
	return [
			Data.TYPE.STRING,
			Data.TYPE.U16,
			Data.TYPE.U16,
			Data.TYPE.U16,
			Data.TYPE.U8,
			Data.TYPE.U8,
			Data.TYPE.U16
		]

func get_state_vector():
	set_deferred("cached_action", ACTIONS.NONE)
	
	return [
			uname,
			int(hue),
			round(position.x),
			round(position.y),
			int(cached_action),
			int(Controls.LEFT in controls) | 2*int(Controls.RIGHT in controls),
			weapon_id
		]

func apply_state_vector(timestamp, diff_vector, vector):
	if vector[0] != uname:
		self.uname = vector[0]
	sprite2.self_modulate.h = vector[1] / 360.0
	hue = vector[1]
	
	var target_position = Vector2(vector[2], vector[3])
	last_tick = timestamp
	
	if (!main and controls.empty()) or Com.time_greater(timestamp, last_controls + 3):
		var old_position = position
		
		if old_position.round() != target_position:
			position = target_position
#		elif last_server_position != Vector2():
#			position = last_server_position
		
		if has_meta("initialized"): sprite.position += (old_position - position)
	else:
		if (target_position - position).length_squared() > 65536:
			desync += 1
			
			if desync == 5:
				position = target_position
		else:
			desync = 0
	
#	if (diff_vector & 4) > 0:
#		last_server_position.x = vector[2]
#	if (diff_vector & 8) > 0:
#		last_server_position.y = vector[3]
	
	action = vector[4]
	
	if !main:
		if vector[5] & 1:
			controls[Controls.LEFT] = true
		if vector[5] & 2:
			controls[Controls.RIGHT] = true
	
	if vector[6] != weapon_id:
		weapon_id = vector[6]
		set_weapon(weapon_id)

func set_frame():
	if sprite:
		sprite2.frame = sprite.frame

func set_abilities(abis):
	if abis is String:
		abilities = parse_json(abis)
	else:
		abilities = abis

func on_active_timeout():
	if action == ACTIONS.HOVER:
		action = ACTIONS.NONE

func on_trigger_timeout():
	cooldown = false

func on_save():
	preload("res://Nodes/Effects/PopupText.tscn").instance().start(self, "Saved!", Color.cyan)