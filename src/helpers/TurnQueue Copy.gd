extends YSort

onready var blue_team = $BlueTeam
onready var red_team = $RedTeam

signal changed_leader(leader)

var active_team_index : int = 0

var active_character

var active_blue_character_index = 0
var active_red_character_index = -1
var active_character_indices : Array = []

func _ready():
	#TODO add connections to all
	active_character_indices = [active_blue_character_index, active_red_character_index]
	for child in blue_team.get_children():
		child.setup(self) 
	for child in red_team.get_children():
		child.setup(self) 
	
func setup(o):
	connect("changed_leader", o, "change_camera_leader")
	set_next_active_character()
	#TODO have level call this
	
func set_active_character(child):
	active_character = child
	child.set_active()
	
func choose_next_active_character():
	#TODO choose per team, add teams in separate nodes
	
	#change from blue to red team and vice versa
	active_team_index = (active_team_index + 1) % get_child_count()

	if get_child(active_team_index).get_child_count() > 0:
		active_character_indices[active_team_index] = (active_character_indices[active_team_index] + 1) % get_child(active_team_index).get_child_count()
		set_next_active_character()
	else:
		active_team_index = (active_team_index + 1) % get_child_count()
		if get_child(active_team_index).get_child_count() > 0:
			active_character_indices[active_team_index] = (active_character_indices[active_team_index] + 1) % get_child(active_team_index).get_child_count()
			set_next_active_character()
			active_character.set_physics_process(false)

func set_next_active_character():
	emit_signal("changed_leader", get_child(active_team_index).get_child(active_character_indices[active_team_index]))
	set_active_character(get_child(active_team_index).get_child(active_character_indices[active_team_index]))
