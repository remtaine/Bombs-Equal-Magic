extends Camera2D

var leader = null
onready var camera_man = get_parent()

func _ready():
	pass

func change_leader(f):
	leader = f
	current = true
