class_name Mage
extends Character

const GRAVITY = 3

onready var sprite := $AnimatedSprite
onready var crosshair_pivot := $CrosshairPivot
onready var crosshair := $CrosshairPivot/Crosshair
onready var state_label := $StateLabel
onready var hp_label := $HPLabel
onready var bomb_resource := preload("res://src/weapons/Bomb.tscn")
onready var weapons_holder := get_parent().get_parent().get_node("Weapons")
onready var camera := $Camera2D

export var instance_name : String = "Mage"
export var team : String = "Team 1"
export var is_bot : bool = false

var currently_selected = false
var is_flipped : bool = false

var hp = 100

var run_accel : int = 25
var jump_speed : int = 100
var ground_friction : int = 25
var max_speed : int = 100
var current_speed : Vector2 = Vector2(0, 0)

var _state : String = "NONE"
var _phase : String = "NONE"

signal turn_done

var TEAMS = {
	player1 = "Team 1",
	player2 = "Team 2",
	player3 = "Team 3",
	player4 = "Team 4",
}


var PHASES = {
	IDLE = "IDLE PHASE",
	MOVE = "MOVING PHASE",
	SHOOT = "SHOOTING PHASE"
}

var STATES = {
	#for move phase
	IDLE = "IDLE",
	RUN = "RUNNING",
	JUMP = "JUMPING",
	
	#for shoot phase
	AIM = "AIMING",
	SHOOT = "SHOOTING",
}

func _ready():
	change_phase(PHASES.IDLE)
	change_state(STATES.IDLE)
	set_physics_process(false)
	crosshair_pivot.visible = false

func setup(m):
	connect("turn_done", m, "choose_next_active_character")

func set_active():
	camera.current = true
	set_physics_process(true)
	change_phase(PHASES.MOVE)
	change_state(STATES.IDLE)
	print("NEW CHARACTER")
	
func set_inactive():
	emit_signal("turn_done")
	change_phase(PHASES.IDLE)
	change_state(STATES.IDLE)
	set_physics_process(false)

func _physics_process(delta):
	match _phase:
		PHASES.MOVE:
			move()
		PHASES.SHOOT:
			shoot()

func move():
	if not is_bot:
		interpret_input()
	else:
		do_ai_stuff()
		
	match _state:
		STATES.JUMP:
			if current_speed.y > 0 and sprite.animation == "jump_up":
				sprite.set_animation("jump_down")
			if is_on_floor():
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

		STATES.IDLE:
			if current_speed.x != 0:
				current_speed.x = max(0, current_speed.x - ground_friction) 

	if is_flipped:
		crosshair_pivot.scale.x = -1
	else:
		crosshair_pivot.scale.x = 1
		
	current_speed.y += 3

	current_speed = move_and_slide(current_speed, Vector2.UP)

func shoot():
	if not is_bot:
		interpret_input()
	else:
		do_ai_stuff()

func update_health(dmg):
	hp -= dmg
	hp_label.text = String(hp)
	if hp > 0:
		pass
		#TODO add tween
	else:
		pass
		#TODO die
		
func enter_state():
	match _state:
		STATES.JUMP:
			sprite.set_animation("jump_up")
			current_speed.y = -jump_speed
			
		STATES.RUN:
			sprite.set_animation("run")

		STATES.IDLE:
			sprite.set_animation("idle")
		STATES.SHOOT:
			var bomb = bomb_resource.instance()
			bomb.setup(self, crosshair.global_position, crosshair.global_position - crosshair_pivot.global_position)
			weapons_holder.add_child(bomb)

func interpret_input():
	match _phase:
		PHASES.SHOOT:
			if _state == STATES.AIM:
				if Input.is_action_just_pressed("select"):
					change_state(STATES.SHOOT)
					crosshair_pivot.visible = false
				elif Input.is_action_pressed("aim_up"):
					if is_flipped:
						crosshair_pivot.rotation_degrees += 1
					else:
						crosshair_pivot.rotation_degrees -= 1
				elif Input.is_action_pressed("aim_down"):
					if is_flipped:
						crosshair_pivot.rotation_degrees -= 1
					else:
						crosshair_pivot.rotation_degrees += 1
		PHASES.MOVE:
			if Input.is_action_just_pressed("select") and current_speed == Vector2.ZERO:
				change_phase(PHASES.SHOOT)
				return
			elif Input.is_action_pressed("jump") or _state == STATES.JUMP:
				change_state(STATES.JUMP)
			elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				change_state(STATES.RUN)
			else:
				change_state(STATES.IDLE)
	
func do_ai_stuff():
		match _phase:
			PHASES.SHOOT:
				if _state == STATES.AIM:
					pass #TODO add aiming stuff
			PHASES.MOVE:
				pass #TODO add moving stuff
	
func bomb_exploded():
	#TODO add timer before setting inactive
	set_inactive()
	
func exit_state():
	#exits current state
	pass

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
