class_name TurnQueue

extends YSort

var active_character
var active_character_index = 0
func _ready():
	#TODO add connections to all
	for child in get_children():
		child.setup(self) 
	
	set_active_character(get_child(active_character_index))

func set_active_character(child):
	active_character = child
	child.set_active()
	
func choose_next_active_character():
	active_character_index = (active_character_index + 1) % get_child_count()
	set_active_character(get_child(active_character_index))
