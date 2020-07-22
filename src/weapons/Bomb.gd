class_name Bomb
extends Weapon

signal finished_exploding

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

func _ready():
	set_process(false)
	speed = 300
	damage = 100
	knockback = 25
	max_distance = 12
	
	sprite.offset.y = 0
	
	sprite.set_animation("ready")
	hitbox.setup(self)
	stream_particles.visible = true
	setup_sounds()

func setup_sounds():
	sound_explosion_array = [sound_explosion1]

func _physics_process(delta):
	if sprite.animation != "explode":
		velocity.y += 3
		velocity = move_and_slide(velocity,Vector2.UP)
	
	if is_on_floor():
		if timer.is_stopped() and sprite.animation == "ready":
			timer.start()
#		if velocity.x < 0:
#			velocity.x = max(0, abs(velocity.x) - ground_friction)
#			velocity.x *= -1
#		else:
#			velocity.x = max(0, abs(velocity.x) - ground_friction)
	
	if get_slide_count() > 0:
		if not has_played_bounce:
			play_sound("bounce")
			has_played_bounce = true
		
		var collision = get_slide_collision(0)
		if collision != null:
			direction = direction.bounce(collision.normal) # do ball bounce
			strength *= 0.7
			velocity = speed * direction * strength
			if strength <= 0.05:
				strength = 0
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
	if sprite.animation == "go":
		stream_particles.visible = false
		#add screenshake
		play_sound("explode")
		sprite.set_animation("explode")
#		sprite.offset.y = -12
		scale *= 2
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
