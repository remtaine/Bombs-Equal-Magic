class_name Weapon
extends RigidBody2D #TODO REVERT TO KinematicBody2D

var velocity : Vector2 = Vector2.ZERO
var max_velocity : Vector2 = Vector2.ZERO
var speed : int = 300
var strength : float = 0.0
var direction : Vector2 = Vector2.ZERO

var damage : int = 50 
var knockback : int = 25
var max_distance : int = 12

var owned_by = null

onready var sprite := $AnimatedSprite
onready var label := $Labels/TimerLabel
onready var hitbox := $Hitbox
onready var stream_particles := $StreamParticles

signal did_terrain_damage(pos, radius)

func ready():
	pass
	
func setup(o, pos, dir, throw_strength): #throw strength is from 20 to 100, output should be 100 to 300
	owned_by = o
	direction = dir.normalized()
	strength = float(throw_strength/100)
	global_position = pos
	velocity = speed * direction * strength
	max_velocity = speed * direction
	connect("finished_exploding", o, "bomb_exploded")
	connect("did_terrain_damage", o, "_on_terrain_damage")

func _on_terrain_damage(pos, radius):
	emit_signal("did_terrain_damage", pos, radius)

func apply_stored_force():
	apply_central_impulse(velocity)	
