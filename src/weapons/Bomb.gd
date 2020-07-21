extends KinematicBody2D

signal finished_exploding

var velocity : Vector2 = Vector2.ZERO
var speed : int = 100
var ground_friction : int = 5
var damage : int = 30 

var owned_by = null

onready var sprite := $AnimatedSprite
onready var timer := $ExplodeTimer
onready var label := $Labels/TimerLabel
onready var hitbox := $Hitbox

onready var explosion_audio := $Audio/ExplosionAudio
onready var sound_explosion_array : Array = []
onready var sound_explosion1 := preload("res://sounds/explosions/Explosion_1.wav")
onready var sound_explosion2 := preload("res://sounds/explosions/Explosion_2.wav")
onready var sound_explosion3 := preload("res://sounds/explosions/Explosion_3.wav")
onready var sound_explosion4 := preload("res://sounds/explosions/Explosion_4.wav")
onready var sound_explosion5 := preload("res://sounds/explosions/Explosion_5.wav")

func _ready():
	sprite.set_animation("ready")
	hitbox.setup(self)
	
	setup_sounds()
	
func setup(o, pos, dir):
	owned_by = o
	position = to_local(pos)
	velocity = speed * dir.normalized()
	connect("finished_exploding", o, "bomb_exploded")

func setup_sounds():
	sound_explosion_array = [sound_explosion1]

func _physics_process(delta):
	if sprite.animation != "explode":
		velocity.y += 3
	velocity = move_and_slide(velocity,Vector2.UP)
	
	if is_on_floor():
		if timer.is_stopped() and sprite.animation == "ready":
			timer.start()
		if velocity.x < 0:
			velocity.x = max(0, abs(velocity.x) - ground_friction)
			velocity.x *= -1
		else:
			velocity.x = max(0, abs(velocity.x) - ground_friction)
			
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
