extends Label

onready var timer = get_parent()

func _ready():
	pass
	
func _process(delta):
	text = String(int(ceil(timer.time_left)))
