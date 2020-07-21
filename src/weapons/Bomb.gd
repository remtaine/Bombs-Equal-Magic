extends KinematicBody2D

signal finished_exploding

var velocity : Vector2 = Vector2.ZERO
var speed : int = 100
var ground_friction : int = 5
var damage : int = 30 

var owned_by = null
onready var sprite := $AnimatedSprite
onready var timer := $ExplodeTimer
onready var label := $TimerLabel
onready var hitbox := $Hitbox

func _ready():
	sprite.set_animation("ready")
	hitbox.setup(self)
	
func setup(o, pos, dir):
	owned_by = o
	position = to_local(pos)
	velocity = speed * dir.normalized()
	connect("finished_exploding", o, "bomb_exploded")
	
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
		sprite.set_animation("explode")
		position.y -= 24
		scale *= 2
		
	elif sprite.animation == "explode":	
		emit_signal("finished_exploding")
		queue_free()

func _on_AnimatedSprite_frame_changed():
	if sprite.animation == "explode":
		if sprite.frame == 5: # on explosion
			hitbox.activate()
		if sprite.frame == 6:
			hitbox.deactivate()
