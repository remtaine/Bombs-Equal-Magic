class_name Orb
extends Weapon

signal finished_exploding

export var instance_name = "Orb"
var ground_friction : int = 0
#dist of 0-3 = 100%
#dist of 4-6 = 75%
#dist of 7-9 = 50%
#dist of 10-12 = 25%

onready var timer := $ExplodeTimer
onready var camera := $Camera2D
var timer_on = false
onready var explosion_audio := $Audio/ExplosionAudio
onready var sound_explosion_array : Array = []
onready var sound_explosion1 := preload("res://sounds/orb/Orb Hit.wav")
onready var sound_explosion2 := preload("res://sounds/explosions/Explosion_2.wav")
onready var sound_explosion3 := preload("res://sounds/explosions/Explosion_3.wav")
onready var sound_explosion4 := preload("res://sounds/explosions/Explosion_4.wav")
onready var sound_explosion5 := preload("res://sounds/explosions/Explosion_5.wav")

onready var sound_countdown := preload("res://sounds/orb/Orb Shoot.wav")
onready var sound_countdown_done := preload("res://sounds/bomb countdown/countdown hit 0.wav")

onready var bounce_audio := $Audio/BounceAudio
onready var sound_bounce := preload("res://sounds/bomb countdown/bomb bounce2.wav")

var has_played_bounce : bool = false

func _init():
	speed = 100
	randomize()
	damage = 18 + (randi() % 7)
	knockback = 75
	max_distance = 10
	
func _ready():
	sprite.offset.y = 0
	mode = RigidBody2D.MODE_CHARACTER
	
	hitbox.setup(self, false, 20, true, true, knockback)
	stream_particles.visible = true
	setup_sounds()
	
func setup(o, pos, dir, throw_strength): #throw strength is from 20 to 100, output should be 100 to 300
	owned_by = o
	direction = dir.normalized()
	strength = float(throw_strength/100)
	global_position = (pos)
	velocity = speed * direction
	velocity = speed * direction
	max_velocity = speed * direction
	connect("finished_exploding", o, "bomb_exploded")
	connect("did_terrain_damage", o, "_on_terrain_damage")
	$ExplodeTimer.wait_time = $ExplodeTimer.wait_time * strength

func setup_sounds():
	sound_explosion_array = [sound_explosion1]

func _physics_process(delta):
	if not $ExplodeTimer.is_stopped(): #ie the timer is running
		var x = ceil($ExplodeTimer.time_left)
		x = int(x)
		x = String (x)
		if label.text != x:
			if x != "":
				play_sound("countdown")
			label.text = String(x)
	elif not timer_on:
		timer_on = true
		$ExplodeTimer.start()
		label.text = String(ceil($ExplodeTimer.wait_time))
		
func _on_AnimatedSprite_frame_changed():
	if sprite.animation == "explode":
		if sprite.frame == 1: # on explosion
			hitbox.activate()
		if sprite.frame == 4:
			hitbox.deactivate()

func play_sound(sound):
	match sound:
		"explode":
			explosion_audio.stream = sound_explosion_array[0]
			explosion_audio.play()
		"countdown":
			explosion_audio.stream = sound_countdown
			explosion_audio.play()
		"countdown done":
			explosion_audio.stream = sound_countdown_done
			explosion_audio.play()
		"bounce":
			bounce_audio.stream = sound_bounce
			bounce_audio.play()

func _on_ExplodeTimer_timeout():
	label.text = ""
	mode = RigidBody2D.MODE_STATIC
	stream_particles.visible = false
	#add screenshake
	$AnimationPlayer.stop()
	sprite.self_modulate.a = 1.0
	play_sound("explode")
	sprite.set_animation("explode")
#	sprite.offset.y = -12
	sprite.scale *= 5
#	camera.position.y +=2

func _on_AnimatedSprite_animation_finished():
	if sprite.animation == "explode":
		print("DONE EXPLODING")
		yield(get_tree().create_timer(4.0), "timeout")
		emit_signal("finished_exploding")
		queue_free()
