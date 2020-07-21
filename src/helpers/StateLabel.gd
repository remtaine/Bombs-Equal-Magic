extends Label


export var is_on = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_on:
		visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
