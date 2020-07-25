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


#onready var ai_timer : Timer = $AITimer
#onready var xxx := xxx
#onready var xxx := preload("")
#onready var xxx := preload("")

export var instance_name : String = "Mage"
export var team : String = "Blue"
export var team_color := Color()
export var sprite_type : String = "Mage"
export var is_bot : bool = false

var damage_just_taken : int = 0
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
var ground_friction : int = 5
var max_speed : int = 30
var current_speed : Vector2 = Vector2(0, 0)

var forced = false
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
signal just_died (character)

var WEAPONS = {
	BOMB = 0,
#	SPEAR = 1,
	ORB = 1
}
var PHASES = {
	IDLE = "IDLE PHASE",
	MOVE = "MOVING PHASE",
	CHOOSE_WEAPON = "CHOOSING WEAPON PHASE",
	SHOOT = "SHOOTING PHASE"
}

var _ai_state : String = "NONE"

var AI_STATES = {
	IDLE = "NONE",
	CHOOSE_ENEMY = "choosing enemy",
	FACE_ENEMY = "facing enemy",
	PLAN_STRENGTH = "plan strength",
	START_AIM = "start aim",
	CHANGE_WEAPON = "change weapon",
	AIM = "aim",
	START_THROW = "start throw",
	HOLD_THROW = "hold throw",
}

var STATES = {
	#for move phase
	IDLE = "IDLE",
	RUN = "RUNNING",
	JUMP = "JUMPING",
	
	HURT = "HURT",
	DIE = "DEAD",
	
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
	connect("just_died", o, "_on_character_died")

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
	crosshair_pivot.visible = false
	crosshair_pivot.rotation_degrees = 0
	currently_selected = false
	emit_signal("turn_done")
	change_phase(PHASES.IDLE)
	change_state(STATES.IDLE)
	can_input = false

#TODO remove integrateforces, return physics process
func _physics_process(delta):
	match _phase:
		PHASES.MOVE:
			move()
		PHASES.SHOOT:
			shoot()
		PHASES.IDLE:
			if _state == STATES.HURT:
				if is_on_floor():
					apply_friction()
				else:
					pass
#					apply_friction(0.2)

	current_speed.y += 3
	current_speed = move_and_slide(current_speed, Vector2.UP, true, 4, 1.0472)

func _process(delta):
	hp_label.text = String(ceil(hp_shown))
	
func move():
	var inputs = null
	if can_input:
			inputs = interpret_input(receive_raw_input())
	
#	is_on_floor = state.get_contact_count() > 0 and int(state.get_contact_collider_position(0).y) >= int(global_position.y)
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

			if inputs != null and inputs.run_direction == -1:
				sprite.flip_h = true
				current_speed.x *= -1
				is_flipped = true
			elif inputs != null and inputs.run_direction == 1:
				sprite.flip_h = false
				is_flipped = false
			
			
#				state.linear_velocity.x = -current_speed.x
#				state.linear_velocity.x = current_speed.x
		STATES.IDLE:
			apply_friction()
	
	if is_flipped:
		crosshair_pivot.scale.x = -1
#		weapons.scale.x = -1
	else:
		crosshair_pivot.scale.x = 1
#		weapons.scale.x = 1

func apply_friction(multiplier = 1):
	if current_speed.x < 0:
		current_speed.x = min(0, current_speed.x + (ground_friction* multiplier))
	elif current_speed.x > 0:
		current_speed.x = max(0, current_speed.x - (ground_friction* multiplier))

func shoot():
	if can_input:
			interpret_input(receive_raw_input())


func update_health(dmg):
	if dmg > 0:
		damage_just_taken = dmg
		change_state(STATES.HURT, true)

func spawn_weapon():
	play_sound("launch")

	match sprite_type:
		"Mage":#WEAPONS.BOMB:
			var bomb = bomb_resource.instance()
			bomb.setup(self, crosshair.global_position, crosshair.global_position - crosshair_pivot.global_position, arrow.value)
			others_handler.add_child(bomb)

			emit_signal("changed_leader", bomb)
			crosshair_pivot.visible = false
			arrow.value = 0
#		WEAPONS.SPEAR:
#			pass
		"Mushroom":#WEAPONS.ORB:
			var orb = orb_resource.instance()
			orb.setup(self, crosshair.global_position, crosshair.global_position - crosshair_pivot.global_position, arrow.value)
			others_handler.add_child(orb)

			emit_signal("changed_leader", orb)
			crosshair_pivot.visible = false
			arrow.value = 0

func receive_raw_input():
	var a
	if not is_bot:
		a =  {
				run_direction = get_input_direction(),
				is_running = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"),
				is_jumping = Input.is_action_just_pressed("jump"),
				is_moving_aim = Input.is_action_pressed("aim_down") or Input.is_action_pressed("aim_up"),
				aim_direction = get_aim_movement_direction(),
				is_select = Input.is_action_just_pressed("select"),
				is_select_hold = Input.is_action_pressed("select"),
				is_changing_weapon = Input.is_action_just_pressed("change_weapon_right") or Input.is_action_just_pressed("change_weapon_left"),
				weapon_change_direction = get_weapon_change_direction(),
				is_panning = Input.is_action_pressed("panning"),
				panning_direction = get_panning_direction(),
			}
	else:	
		
		var run_direction = 0
		var is_running = false
		var is_jumping = false
		var is_moving_aim = false
		var aim_direction = 0
		var is_select = false
		var is_select_hold = false
		var is_changing_weapon = false
		var weapon_change_direction = 0
		var is_panning = false
		var panning_direction = 0
		
		print_debug("AI STATE AT ", _ai_state)
		
		match _phase:
			PHASES.MOVE:
				if forced:
					print("FORCE IT")
					is_select = true
				match _ai_state:
					AI_STATES.IDLE:
						change_ai_state(AI_STATES.CHOOSE_ENEMY)
					AI_STATES.CHOOSE_ENEMY:
						if opposing_character != null:
							ai_planned_enemy = opposing_character
							change_ai_state(AI_STATES.FACE_ENEMY)
						else:
							change_ai_state(AI_STATES.IDLE)
					AI_STATES.FACE_ENEMY:
						if ai_planned_enemy.global_position.x - global_position.x > 2: #ie should face right
							run_direction = 1
							is_running = true
						elif ai_planned_enemy.global_position.x - global_position.x < -2: #ie should face left
							run_direction = -1
							is_running = true
						tween.interpolate_callback(self, 0.5, "change_ai_state", AI_STATES.START_AIM)
						tween.start()
					AI_STATES.PLAN_STRENGTH:
						pass
#						var x = 100
#						if ai_planned_enemy != null:
#							x = global_position.distance_to(ai_planned_enemy.global_position)
#						randomize()
#						var temp
#						if is_flipped:
#							temp = float((85 + randi() % 3)/10.0)
#						else:
#							temp = float((100 + randi() % 3)/10.0)
#						ai_planned_strength = ceil(x/temp)
#						change_ai_state(AI_STATES.START_AIM)						
					AI_STATES.START_AIM:
						var dist = 100
						if ai_planned_enemy != null:
							dist = global_position.distance_to(ai_planned_enemy.global_position)
						randomize()
						var divisor
						if is_flipped:
							divisor = float((90 + randi() % 3)/10.0)
						else:
							divisor = float((85 + randi() % 3)/10.0)
						ai_planned_strength = ceil(dist/divisor)
						is_select = true
						change_ai_state(AI_STATES.CHANGE_WEAPON)
			PHASES.SHOOT:
				match _ai_state:
					AI_STATES.CHANGE_WEAPON:
#						if _weapon != WEAPONS.ORB:
#							is_changing_weapon = true
#							weapon_change_direction = 1
#						else:
						change_ai_state(AI_STATES.AIM)
					AI_STATES.AIM:
#						crosshair_pivot.look_at(ai_planned_enemy.position)
#						if is_flipped:
#							crosshair_pivot.rotation_degrees *= -1
#							else:
#								aim_direction = 1
						var x = acos(abs((global_position - ai_planned_enemy.global_position).normalized().x))
						x= rad2deg(x)
						if global_position.y < ai_planned_enemy.global_position.y and is_flipped: #ie enemy is below
							x *= -1
						elif global_position.y > ai_planned_enemy.global_position.y and not is_flipped: #ie enemy is below
							x *= -1 #yes theyre the same thing, i dont want the line to be too long
#						print_debug("NOW COMPARING ", x, " TO ", crosshair_pivot.rotation_degrees)
						var y = (x - crosshair_pivot.rotation_degrees)
						if is_flipped:
							if y < -2: #ie 85 - 90
								is_moving_aim = true
								aim_direction = 1
							elif y > 2:
								is_moving_aim = true
								aim_direction = -1 
							else:
								change_ai_state(AI_STATES.START_THROW)
						else:
							if y > 2:
								is_moving_aim = true
								aim_direction = 1 
							elif y < -2:
								is_moving_aim = true
								aim_direction = -1 
							else:
								change_ai_state(AI_STATES.START_THROW)
					AI_STATES.START_THROW:
						is_select = true
						is_select_hold = true
						change_ai_state(AI_STATES.HOLD_THROW)
					AI_STATES.HOLD_THROW:
						if arrow.value < ai_planned_strength:
							is_select_hold = true
						else:
							change_ai_state(AI_STATES.IDLE)
					_:
						change_ai_state(AI_STATES.CHANGE_WEAPON)
		
		a = {
				run_direction = run_direction,
				is_running = is_running,
				is_jumping = is_jumping,
				is_moving_aim = is_moving_aim,
				aim_direction = aim_direction,
				is_select = is_select,
				is_select_hold = is_select_hold,
				is_changing_weapon = is_changing_weapon,
				weapon_change_direction = weapon_change_direction,
				is_panning = is_panning,	
				panning_direction = panning_direction,
		}
	
	return a

func change_ai_state(s):
	if _ai_state != s:
		_ai_state = s
	
func get_panning_direction():
	pass
	
func get_weapon_change_direction():
	return int(Input.is_action_pressed("change_weapon_right")) - int(Input.is_action_pressed("change_weapon_left"))

func get_aim_movement_direction():
	return int(Input.is_action_pressed("aim_down")) - int(Input.is_action_pressed("aim_up"))
	
func get_input_direction():
	return int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))

func interpret_input(inputs = null):
	match _phase:
		PHASES.SHOOT:
			if _state == STATES.AIM:
				if inputs.is_select:
					change_state(STATES.THROW)
#					crosshair_pivot.visible = false
				elif inputs.is_moving_aim:
					if inputs.aim_direction == -1:
						if is_flipped:
							crosshair_pivot.rotation_degrees += 1
						else:
							crosshair_pivot.rotation_degrees -= 1
					elif inputs.aim_direction == 1:
						if is_flipped:
							crosshair_pivot.rotation_degrees -= 1
						else:
							crosshair_pivot.rotation_degrees += 1
	
					crosshair_pivot.rotation_degrees = clamp(crosshair_pivot.rotation_degrees, -90, 90)
					
				elif inputs.is_changing_weapon:
					if inputs.weapon_change_direction == 1:
						_weapon = (_weapon + 1) % weapons.get_child_count()
						show_current_weapon()
						play_sound("change weapon")
					elif inputs.weapon_change_direction == -1:
						_weapon = (_weapon - 1) % weapons.get_child_count()
						if _weapon < 0:
							_weapon += weapons.get_child_count()
						show_current_weapon()
						play_sound("change weapon")
					
			elif _state == STATES.THROW:
				if inputs.is_select_hold:
					arrow.value += 1
					if arrow.value >= 100:
						change_state(STATES.SHOOT)
				else:
					change_state(STATES.SHOOT)
		
		PHASES.MOVE:
			if inputs != null and inputs.is_panning:
				emit_signal("panning")
				can_input = false
				change_state(STATES.IDLE)
				return
			if inputs.is_select and (_state == STATES.IDLE):
				change_phase(PHASES.SHOOT)
				return
			elif (inputs.is_jumping and is_on_floor) or _state == STATES.JUMP:
				change_state(STATES.JUMP)
			elif (inputs.is_running) and is_on_floor:
				change_state(STATES.RUN)
			else:
				change_state(STATES.IDLE)
	return inputs
	
func do_ai_stuff():
	pass

func simulate_button_press(key):
	simulate_button_hold(key)
	yield(get_tree().create_timer(0.2), "timeout")
	simulate_button_release(key)

func simulate_button_hold(action):
	var event = InputEvent.new()
	event.set_as_action( action, true) # second parameter specifies if pressed
	get_tree().input_event( event )
	
		
#	var a = InputEventAction.new()
#	a.action = action
#	a.pressed = true
#	Input.parse_input_event(a)

func simulate_button_release(action):
	var event = InputEvent.new()
	event.set_as_action( action, false) # second parameter specifies if pressed
	get_tree().input_event( event )
#	var a = InputEventAction.new()
#	a.action = action
#	a.pressed = false
#	Input.parse_input_event(a)



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
		STATES.HURT:
				can_input = false
				set_process(true) #for updating text!
				sprite.set_animation("hurt")
				emit_signal("took_damage", team, min(hp, damage_just_taken))	
				hp = max(0, hp - damage_just_taken)
				tween.interpolate_property(self, "hp_shown", hp_shown, hp, 2.0, tween.TRANS_LINEAR, tween.EASE_IN)
				tween.start()
		STATES.DIE:
			emit_signal("just_died", self)
			can_input = false
			$Labels.visible = false
			play_sound("die")
			sprite.set_animation("die")
	
		STATES.AIM:
			_weapon = WEAPONS.BOMB
		STATES.THROW:
			play_sound("charge attack")
			emit_signal("pause_timer")
			if not is_bot:
				arrow.value = 20
			else:
				arrow.value = 0
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

func change_state(state, override = false):
	if _state != state or override:
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
			if is_bot:
				change_ai_state(AI_STATES.CHANGE_WEAPON)
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
	if is_bot and _state != STATES.HURT:
		yield(get_tree().create_timer(1.0), "timeout")
	else:
		if hp > 0:
#			can_input = true
			set_process(false)
			change_state(STATES.IDLE)
		else:
			change_state(STATES.DIE)


func _on_AnimatedSprite_animation_finished():
	if sprite.animation == "die":
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

func force_move():
	if is_bot:
		forced = true

func _on_AITimer_timeout():
	match _ai_state:
		AI_STATES.FACE_ENEMY:
			change_ai_state(AI_STATES.PLAN_STRENGTH)
