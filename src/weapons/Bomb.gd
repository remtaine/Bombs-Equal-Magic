class_name Bomb
extends Weapon

signal finished_exploding

var ground_friction : int = 5
#dist of 0-3 = 100%
#dist of 4-6 = 75%
#dist of 7-9 = 50%
#dist of 10-12 = 25%

onready var timer := $ExplodeTimer

onready var explosion_audio := $Audio/ExplosionAudio
onready var sound_explosion_array : Array = []
onready var sound_explosion1 := preload("res://sounds/explosions/Explosion_1.wav")
onready var sound_explosion2 := preload("res://sounds/explosions/Explosion_2.wav")
onready var sound_explosion3 := preload("res://sounds/explosions/Explosion_3.wav")
onready var sound_explosion4 := preload("res://sounds/explosions/Explosion_4.wav")
onready var sound_explosion5 := preload("res://sounds/explosions/Explosion_5.wav")

func _ready():
	speed = 300
	damage = 50 
	knockback = 25
	max_distance = 12
	
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
		var collision = get_slide_collision(0)
		if collision != null:
			direction = direction.bounce(collision.normal) # do ball bounce
			strength *= 0.7
			velocity = speed * direction * strength
	
	if not timer.is_stopped():
		var x = ceil(timer.time_left)
		x = int(x)
		label.text = String(x)
		#TODO add bounce

func _on_ExplodeTimer_timeout():
	sprite.set_animation("go")
	label.text = ""
	
func _on_AnimatedSprite_animation_finished():
	if sprite.animation == "go":
		stream_particles.visible = false	
		play_sound("explode")
		sprite.set_animation("explode")
		position.y -= 24
		scale *= 2

func _on_AnimatedSprite_frame_changed():
	if sprite.animation == "explode":
		if sprite.frame == 5: # on explosion
			hitbox.activate()
		if sprite.frame == 6:
			hitbox.deactivate()

func play_sound(sound):
	match sound:
		"explode":
			explosion_audio.stream = sound_explosion_array[0]
			explosion_audio.play()

func _on_ExplosionAudio_finished():
	if explosion_audio.stream in sound_explosion_array:
		emit_signal("finished_exploding")
		queue_free()

func _on_TooLongTimer_timeout():
	if timer.is_stopped() and sprite.animation == "ready":
		timer.start()
