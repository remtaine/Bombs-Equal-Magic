class_name Bomb
extends Weapon

signal finished_exploding

export var instance_name = "Bomby"
var ground_friction : int = 5
#dist of 0-3 = 100%
#dist of 4-6 = 75%
#dist of 7-9 = 50%
#dist of 10-12 = 25%

onready var timer := $ExplodeTimer
onready var camera := $Camera2D

onready var explosion_audio := $Audio/ExplosionAudio
onready var sound_explosion_array : Array = []
onready var sound_explosion1 := preload("res://sounds/explosions/Explosion_1.wav")
onready var sound_explosion2 := preload("res://sounds/explosions/Explosion_2.wav")
onready var sound_explosion3 := preload("res://sounds/explosions/Explosion_3.wav")
onready var sound_explosion4 := preload("res://sounds/explosions/Explosion_4.wav")
onready var sound_explosion5 := preload("res://sounds/explosions/Explosion_5.wav")

onready var sound_countdown := preload("res://sounds/bomb countdown/countdown_bomb.wav")
onready var sound_countdown_done := preload("res://sounds/bomb countdown/countdown hit 0.wav")

onready var bounce_audio := $Audio/BounceAudio
onready var sound_bounce := preload("res://sounds/bomb countdown/bomb bounce2.wav")

var has_played_bounce : bool = false

func _init():
	speed = 500
	damage = 50
	knockback = 100
	max_distance = 36
	
func _ready():	
	sprite.offset.y = 0
	mode = RigidBody2D.MODE_CHARACTER
	
	sprite.set_animation("ready")
	hitbox.setup(self, true, max_distance, true, knockback)
	stream_particles.visible = true
	setup_sounds()
	set_process(false)
		
func setup_sounds():
	sound_explosion_array = [sound_explosion1]

func _physics_process(delta):
#	if hitbox.collision_shape.disabled:
#		print_debug("hitbox disabled")
#	else:
#		print_debug("hitbox IS ENABLED")	
	if sprite.animation != "explode":
		velocity.y += 3
#		velocity = move_and_slide(velocity,Vector2.UP) #CHANGE
	
#	if is_on_floor():
#		if timer.is_stopped() and sprite.animation == "ready":
#			timer.start()
#		if velocity.x < 0:
#			velocity.x = max(0, abs(velocity.x) - ground_friction)
#			velocity.x *= -1
#		else:
#			velocity.x = max(0, abs(velocity.x) - ground_friction)
	
	if get_colliding_bodies().size() > 0:
		if not has_played_bounce:
			play_sound("bounce")
			has_played_bounce = true
			
	else:
		has_played_bounce = false
		
	if not timer.is_stopped(): #ie the timer is running
		var x = ceil(timer.time_left)
		x = int(x)
		x = String (x)
		if label.text != x:
			if x != "0":
				play_sound("countdown")
			label.text = String(x)
		
		#TODO add bounce

func _on_ExplodeTimer_timeout():
	play_sound("countdown done")
	sprite.set_animation("go")
	label.text = ""
	
func _on_AnimatedSprite_animation_finished():
	if sprite.animation == "go": #time to explode!
		mode = RigidBody2D.MODE_STATIC
		stream_particles.visible = false
		#add screenshake
		play_sound("explode")
		sprite.set_animation("explode")
#		sprite.offset.y = -12
		sprite.scale *= 2
		camera.position.y +=2
		#TODO add screenshake!!!
		
func _on_AnimatedSprite_frame_changed():
	if sprite.animation == "explode":
		if sprite.frame == 1: # on explosion
			hitbox.activate()
		if sprite.frame == 6:
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

func _on_ExplosionAudio_finished():
	if explosion_audio.stream in sound_explosion_array:
		emit_signal("finished_exploding")
		queue_free()

func _on_TooLongTimer_timeout():
	if timer.is_stopped() and sprite.animation == "ready":
		timer.start()
