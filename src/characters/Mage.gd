class_name Mage
extends KinematicBody2D

const GRAVITY = 3

onready var sprite := $AnimatedSprite

onready var crosshair_pivot := $CrosshairPivot
onready var crosshair := $CrosshairPivot/Crosshair
onready var arrow := $CrosshairPivot/Arrow

onready var tween := $Tween

onready var state_label := $Labels/StateLabel
onready var hp_label := $Labels/HPLabel
onready var name_label := $Labels/NameLabel

var opposing_character
onready var dust_resource := preload("res://src/effects/Dust.tscn")
onready var bomb_resource := preload("res://src/weapons/Bomb.tscn")
onready var orb_resource := preload("res://src/weapons/Orb.tscn")

onready var others_handler := get_parent().get_parent().get_parent().get_node("Weapons")
onready var weapons = $CrosshairPivot/Weapons
onready var camera := $Camera2D

onready var launch_audio := $Audio/LaunchAudio
onready var sound_launch_array : Array = []
onready var sound_launch1 := preload("res://sounds/launches/Launch_1.wav")
onready var sound_launch2 := preload("res://sounds/launches/Launch_2.wav")
onready var sound_launch3 := preload("res://sounds/launches/Launch_3.wav")
onready var sound_launch4 := preload("res://sounds/launches/Launch_4.wav")
onready var sound_launch5 := preload("res://sounds/launches/Launch_5.wav")
onready var sound_launch6 := preload("res://sounds/launches/Launch_6.wav")
onready var sound_launch7 := preload("res://sounds/launches/Launch_7.wav")

onready var movement_audio := $Audio/MovementAudio
onready var sound_footsteps := preload("res://sounds/movement/footsteps.wav")
onready var sound_jump := preload("res://sounds/movement/Jump.wav")
onready var sound_land := preload("res://sounds/movement/land.wav")
onready var sound_die := preload("res://sounds/hurt/death SFX_7.wav")

onready var aim_weapon_audio := $Audio/AimWeaponAudio
onready var sound_charge_attack := preload("res://sounds/aim weapon/charge_attack.wav")
onready var sound_change_weapon := preload("res://sounds/aim weapon/change_weapon.wav")
onready var sound_moving_aim := preload("res://sounds/aim weapon/moving aim.wav")
onready var sound_hurt := preload("res://sounds/aim weapon/Hit_Hurt6.wav")

onready var select_audio := $Audio/SelectAudio
onready var sound_select := preload("res://sounds/select/Select.wav")
onready var sound_deselect := preload("res://sounds/select/deselect.wav")

#onready var xxx := xxx
#onready var xxx := preload("")
#onready var xxx := preload("")

export var instance_name : String = "Mage"
export var team : String = "Blue"
export var team_color := Color()
export var sprite_type : String = "Mage"
export var is_bot : bool = false

var ai_planned_strength :int = 0
var ai_planned_enemy

var can_input : bool = false
var currently_selected = false
var is_flipped : bool = false

var hp : int = 100
var hp_shown : int = 100

var throw_strength :float = 0.0

var run_accel : int = 10
var jump_speed : int = 100
var ground_friction : int = 10
var max_speed : int = 20
var current_speed : Vector2 = Vector2(0, 0)

var _state : String = "NONE"
var _phase : String = "NONE"
var _weapon = 0

var is_on_floor : bool = true

signal turn_done
signal changed_leader(leader)

signal pause_timer
signal took_damage(team, dmg)
signal panning

signal did_terrain_damage(pos, radius)

var WEAPONS = {
	BOMB = 0,
	SPEAR = 1,
	ORB = 2
}
var PHASES = {
	IDLE = "IDLE PHASE",
	MOVE = "MOVING PHASE",
	CHOOSE_WEAPON = "CHOOSING WEAPON PHASE",
	SHOOT = "SHOOTING PHASE"
}

var STATES = {
	#for move phase
	IDLE = "IDLE",
	RUN = "RUNNING",
	JUMP = "JUMPING",
	
	#for shoot phase
	AIM = "AIMING",
	THROW = "THROWING",
	SHOOT = "SHOOTING",
}

func _ready():
	set_process(false)
	change_phase(PHASES.IDLE)
	change_state(STATES.IDLE)
	crosshair_pivot.visible = false
	
	name_label.text = instance_name
	
	setup_sounds()

func setup(o):
	connect("turn_done", o, "choose_next_active_character")

func level_setup(o):
	connect("changed_leader", o, "change_camera_leader")
	connect("pause_timer", o, "_on_pause_timer")
	connect("took_damage", o, "_on_take_damage")
	connect("panning", o, "_on_panning")
	connect("did_terrain_damage", o, "_on_terrain_damage")
	
func setup_sounds():
	sound_launch_array = [sound_launch1]
	#TODO add other array parts
	
func set_active():
	currently_selected = true
#	camera.current = true
	print("I CAN INPUT NOW ", instance_name)
	change_phase(PHASES.MOVE)
	change_state(STATES.IDLE)
	
func set_inactive():
	crosshair_pivot.rotation_degrees = 0
	currently_selected = false
	emit_signal("turn_done")
	change_state(STATES.IDLE)
	can_input = false

#TODO remove integrateforces, return physics process
func _physics_process(delta):
	match _phase:
		PHASES.MOVE:
			move()
		PHASES.SHOOT:
			shoot()
	
	current_speed.y += 3	
	current_speed = move_and_slide(current_speed, Vector2.UP, true, 4, 1.0472)

func _process(delta):
	hp_label.text = String(ceil(hp_shown))
	
func move():
	if not is_bot:
		if can_input:
			interpret_input()
	else:
		print("DOING AI STUFF FOR MOVE")
		do_ai_stuff()
	
#	is_on_floor = state.get_contact_count() > 0 and int(state.get_contact_collider_position(0).y) >= int(global_position.y)
#	print_debug("AM I ON FLOOR? ", is_on_floor)
	match _state:
		STATES.JUMP:
			if current_speed.y >= 0 and sprite.animation == "jump_up":
				sprite.set_animation("jump_down")
				#TODO add separate fall state
			if is_on_floor() and sprite.animation == "jump_down":
				print("TURNED IDLE")
				change_state(STATES.IDLE)
		
		STATES.RUN:
			current_speed.x = min(max_speed, abs(current_speed.x) + run_accel)

			if Input.is_action_pressed("move_left"):
				sprite.flip_h = true
				current_speed.x *= -1
				is_flipped = true
			elif Input.is_action_pressed("move_right"):
				sprite.flip_h = false
				is_flipped = false
			
			
#				state.linear_velocity.x = -current_speed.x
#				state.linear_velocity.x = current_speed.x
		STATES.IDLE:
			if current_speed.x != 0:
				current_speed.x = max(0, current_speed.x - ground_friction) 
	
	if is_flipped:
		crosshair_pivot.scale.x = -1
#		weapons.scale.x = -1
	else:
		crosshair_pivot.scale.x = 1
#		weapons.scale.x = 1

func shoot():
	if not is_bot:
		if can_input:
			interpret_input()
	else:
		print("DOING AI STUFF FOR SHOOT")
		do_ai_stuff()

func update_health(dmg):
	can_input = false
	set_process(true)
	sprite.set_animation("hurt")
	emit_signal("took_damage", team, min(hp, dmg))	
	hp = max(0, hp - dmg)
	tween.interpolate_property(self, "hp_shown", hp_shown, hp, 2.0, tween.TRANS_LINEAR, tween.EASE_IN)
	tween.start()

func spawn_weapon():
	play_sound("launch")

	match _weapon:
		WEAPONS.BOMB:
			var bomb = bomb_resource.instance()
			bomb.setup(self, crosshair.global_position, crosshair.global_position - crosshair_pivot.global_position, arrow.value)
			others_handler.add_child(bomb)

			emit_signal("changed_leader", bomb)
			crosshair_pivot.visible = false
			arrow.value = 0
		WEAPONS.SPEAR:
			pass
		WEAPONS.ORB:
			var orb = orb_resource.instance()
			orb.setup(self, crosshair.global_position, crosshair.global_position - crosshair_pivot.global_position, arrow.value)
			others_handler.add_child(orb)

			emit_signal("changed_leader", orb)
			crosshair_pivot.visible = false
			arrow.value = 0

func interpret_input():
	match _phase:
		PHASES.SHOOT:
			if _state == STATES.AIM:
				if Input.is_action_just_pressed("select"):
					change_state(STATES.THROW)
#					crosshair_pivot.visible = false
				elif Input.is_action_pressed("aim_down") or Input.is_action_pressed("aim_up"):
					if Input.is_action_pressed("aim_up"):
						if is_flipped:
							crosshair_pivot.rotation_degrees += 1
						else:
							crosshair_pivot.rotation_degrees -= 1
					elif Input.is_action_pressed("aim_down"):
						if is_flipped:
							crosshair_pivot.rotation_degrees -= 1
						else:
							crosshair_pivot.rotation_degrees += 1
	
					crosshair_pivot.rotation_degrees = clamp(crosshair_pivot.rotation_degrees, -90, 90)
					
				elif Input.is_action_just_pressed("change_weapon_right"):
					_weapon = (_weapon + 1) % weapons.get_child_count()
					show_current_weapon()
					play_sound("change weapon")
				elif Input.is_action_just_pressed("change_weapon_left"):
					_weapon = (_weapon - 1) % weapons.get_child_count()
					if _weapon < 0:
						_weapon += weapons.get_child_count()
					show_current_weapon()
					play_sound("change weapon")
					
			elif _state == STATES.THROW:
				if Input.is_action_pressed("select"):
					arrow.value += 1
					if arrow.value >= 100:
						change_state(STATES.SHOOT)
				else:
					change_state(STATES.SHOOT)
		
		PHASES.MOVE:
			if Input.is_action_pressed("panning"):
				emit_signal("panning")
				can_input = false
				change_state(STATES.IDLE)
				return
			if Input.is_action_just_pressed("select") and _state == STATES.IDLE:
				change_phase(PHASES.SHOOT)
				return
			elif (Input.is_action_just_pressed("jump") and is_on_floor) or _state == STATES.JUMP:
				change_state(STATES.JUMP)
			elif (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")) and is_on_floor:
				change_state(STATES.RUN)
			else:
				change_state(STATES.IDLE)
	
func do_ai_stuff():
		match _phase:
			PHASES.SHOOT:
				match _state:
					STATES.AIM:
						#DONE? change to orb
						while _weapon != 2:
							print_debug("CHANGING WEAPON")
							simulate_button_press("change_weapon_right")
						#DONE? aim at enemy
						print_debug("AIMING")
						var x = global_position.angle_to(ai_planned_enemy.global_position)
						if x > crosshair_pivot.rotation_degrees:
							while x > crosshair_pivot.rotation_degrees:
								Input.action_press("aim_up")
							Input.action_release("aim_up")
						elif x < crosshair_pivot.rotation_degrees:
							while x < crosshair_pivot.rotation_degrees:
								Input.action_press("aim_down")
							Input.action_release("aim_down")
						Input.action_press("select")
					STATES.THROW:
						#DONE? charge strength to ai_planned_strength
						print_debug("CHARGING")
						if arrow.value >= ai_planned_strength:
							Input.action_release("select")
			PHASES.MOVE:
				yield(get_tree().create_timer(2.0), "timeout")
				#TODO choose closest enemy
				print_debug("CHOOSING CLOSEST ENEMY")
				ai_planned_enemy = opposing_character
				#DONE? face enemy
				print_debug("FACING ENEMY")
				if ai_planned_enemy.global_position.x > global_position.x: #ie should face right
					simulate_button_press("move_right")
				elif ai_planned_enemy.global_position.x < global_position.x: #ie should face left
					simulate_button_press("move_left")					
				#TODO plan ai_strength
				print_debug("PLANNING STRENGTH")
				ai_planned_strength = 50 #TEMP
				change_phase(PHASES.SHOOT)	
				yield(get_tree().create_timer(0.5), "timeout")

func simulate_button_press(action):
	Input.action_press(action)
	yield(get_tree().create_timer(1.0), "timeout")
	Input.action_release(action)

func show_current_weapon():
	for child in weapons.get_children():
		child.visible = false
	weapons.get_child(_weapon).visible = true
	
func bomb_exploded():
	#TODO add timer before setting inactive
	set_inactive()

func play_sound(sound):
	match sound:
		"launch":
			launch_audio.stream = sound_launch_array[0]
			launch_audio.play()
		"footsteps":
			movement_audio.stream = sound_footsteps
			movement_audio.play()
		"jump":
			movement_audio.stream = sound_jump
			movement_audio.play()
		"land":
			movement_audio.stream = sound_land
			movement_audio.play()
		"die":
			movement_audio.stream = sound_die
			movement_audio.play()
		"hurt":
			aim_weapon_audio.stream = sound_hurt
			aim_weapon_audio.play()
		"change weapon":
			aim_weapon_audio.stream = sound_change_weapon
			aim_weapon_audio.play()
		"charge attack":
			aim_weapon_audio.stream = sound_charge_attack
			aim_weapon_audio.play()
		"moving aim":
			aim_weapon_audio.stream = sound_moving_aim
			aim_weapon_audio.play()
		"select":
			select_audio.stream = sound_select
			select_audio.play()
		"deselect":
			select_audio.stream = sound_deselect
			select_audio.play()
func enter_state():
	match _state:
		STATES.JUMP:
			play_sound("jump")
			sprite.set_animation("jump_up")
			var dust = dust_resource.instance()
			dust.setup("jump", global_position)
			others_handler.add_child(dust)

#			apply_central_impulse(Vector2.UP * jump_speed)
			current_speed.y = -jump_speed
#			current_speed.x = -jump_speed
			
		STATES.RUN:
			sprite.set_animation("run")
		STATES.IDLE:
			sprite.set_animation("idle")
			current_speed.x = 0
		STATES.AIM:
			_weapon = WEAPONS.BOMB
		STATES.THROW:
			play_sound("charge attack")
			emit_signal("pause_timer")
			arrow.value = 20
		STATES.SHOOT:
			aim_weapon_audio.stop()
			spawn_weapon()
			
			can_input = false
			change_phase(PHASES.IDLE)
			change_state(STATES.IDLE)
			
func exit_state():
	match _state:
		STATES.JUMP:
			play_sound("land")
			var dust = dust_resource.instance()
			dust.setup("land", global_position)
			others_handler.add_child(dust)

func change_state(state):
	if _state != state:
		exit_state()
		_state = state
		state_label.text = _state
		enter_state()

func enter_phase():
	match _phase:
		PHASES.IDLE:
			pass
		PHASES.MOVE:
			pass
		PHASES.SHOOT:
			crosshair_pivot.visible = true
			change_state(STATES.AIM)

func exit_phase():
	pass

func change_phase(phase):
	if _phase != phase:
		exit_phase()
		_phase = phase
		enter_phase()

func _on_terrain_damage(pos, radius):
	emit_signal("did_terrain_damage", pos, radius)

func _on_Tween_tween_all_completed(): #only for health so far
	if hp > 0:
		can_input = true
		sprite.set_animation("idle")
		set_process(false)
	else:
		can_input = false
		play_sound("die")
		sprite.set_animation("die")


func _on_AnimatedSprite_animation_finished():
	if sprite.animation == "die":
		yield(get_tree().create_timer(1.0), "timeout")
		if currently_selected:
			set_inactive()
		queue_free() #TODO add to die list


func _on_AnimatedSprite_frame_changed():
	if sprite != null and sprite.animation == "run":
		if sprite_type == "Mage":
			if sprite.frame == 0 or sprite.frame == 3:
				play_sound("footsteps")
		elif sprite_type == "Mushroom":
			if sprite.frame == 2 or sprite.frame == 6:
				play_sound("footsteps")
