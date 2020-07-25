extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var dist_scaled : bool = false
var max_dist : int = 0

var does_recoil : bool = false
var recoil_strength : int = 0

var terrain_damage : bool = false

var owned_by = null
var damage : int = 0

onready var collision_shape := $CollisionShape2D

signal did_terrain_damage(position, radius)

# Called when the node enters the scene tree for the first time.
func _ready():
	deactivate()

func setup(o, d = false, m = 0, t_d = false, r = false, rs = 0):
	owned_by = o
	damage = o.damage
	dist_scaled = d
	max_dist = m
	terrain_damage = t_d
	does_recoil = r
	recoil_strength = rs
	connect("did_terrain_damage", o, "_on_terrain_damage")
	print("TERRAIN DAMAGE IS ", terrain_damage)

func activate():
	collision_shape.disabled = false
	
func deactivate():
	collision_shape.disabled = true


func _on_Hitbox_body_entered(body):
	if body.is_in_group("characters"):
		if dist_scaled and max_dist != 0:
			var dist_to = owned_by.global_position.distance_to(body.global_position)
			var y = abs(max_dist) - abs(dist_to)
			print("DIST FROM ", body.instance_name, " IS ", dist_to)
			
			var x = min(1.0, float((y + 8)/max_dist))			
			x = ceil(damage * (0.6 + (0.4 * x)))
			print("DAMAGE IS ", x)
			body.update_health(x)
		else:
			print(damage)
			body.update_health(damage)
			
		if does_recoil and recoil_strength != 0:
			var v = recoil_strength * (body.global_position - owned_by.global_position).normalized()
			if v.y > 0:
				body.current_speed = Vector2(v.x, -20 - v.y)
			else:
				body.current_speed = Vector2(v.x, -20 + v.y)
	#			body.current_speed = body.move_and_slide(body.current_speed, Vector2.UP)
			print("VEL IS RECOILED ", v)

	if terrain_damage and max_dist != 0:
		emit_signal("did_terrain_damage", global_position, max_dist)
			#TODO add terrain damage
