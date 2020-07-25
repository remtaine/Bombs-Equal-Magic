extends Timer

signal turn_almost_done
var almost_done_activated = false

func _ready():
	pass

func setup(o):
	connect("turn_almost_done", o, "_on_turn_almost_done")

func _physics_process(delta):
	if not is_stopped() and time_left <= wait_time/2 and not almost_done_activated:
		almost_done_activated = true
		emit_signal("turn_almost_done")
	elif is_stopped() and almost_done_activated == true:
		almost_done_activated = false
