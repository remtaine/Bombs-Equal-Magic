class_name TurnQueue

extends YSort

onready var blue_team = $BlueTeam
onready var red_team = $RedTeam
#onready var turn_label = $TurnLabel

signal changed_leader(leader)


#var active_blue_character_index = 0
#var active_red_character_index = -1
#var active_character_indices : Array = []

var active_character
var ac_ref
var active_team_index : int

var team_members : Array = []
var teams : Array = []

func _ready():
	#TODO add connections to all
#	active_character_indices = [active_blue_character_index, active_red_character_index]
	for team in get_children():
		teams.push_back(team)
		var team_mems = []
		for child in team.get_children():
			child.setup(self) 
			team_mems.push_back(child)
		team_members.push_back(team_mems)
	active_team_index = teams.size() - 1
	
func setup(o): #step 0
	connect("changed_leader", o, "change_camera_leader")
	choose_next_active_character()
	#TODO have level call this
	
func choose_next_active_character(bring_back = false): #step 1
	#pop back first to last in current team
	#switch team
	if not bring_back:
		team_members[active_team_index].push_back(team_members[active_team_index].pop_front())
		if teams.size() != 0:
			active_team_index = (active_team_index + 1) % teams.size()
	#choose current at index 0 IF > 0
	if team_members[active_team_index].size() > 0:
		active_character = team_members[active_team_index][0]
		
		ac_ref = weakref(active_character)
		set_next_active_character(active_character, bring_back)
	else:
		var temp = active_team_index
		active_team_index = (active_team_index - 1) 
		if active_team_index < 0:
			active_team_index += teams.size()
		
		team_members[active_team_index].push_front(team_members[active_team_index].pop_back())
		teams.remove(temp)
		choose_next_active_character()
	
	if teams.size() <= 1:
		return
#	else:
#		active_team_index = (active_team_index + 1) % teams.size()
#		if team_members[active_team_index].size() > 0:
#			active_character = team_members[active_team_index][0]
#			active_character.set_physics_process(false)
	#if both 0! SCREWED
		
	
#	active_team_index = (active_team_index + 1) % get_child_count()
#
#	if get_child(active_team_index).get_child_count() > 0:
#		active_character_indices[active_team_index] = (active_character_indices[active_team_index] + 1) % get_child(active_team_index).get_child_count()
#		set_next_active_character()
#	else:
#		active_team_index = (active_team_index + 1) % get_child_count()
#		if get_child(active_team_index).get_child_count() > 0:
#			active_character_indices[active_team_index] = (active_character_indices[active_team_index] + 1) % get_child(active_team_index).get_child_count()
#			set_next_active_character()
#			active_character.set_physics_process(false)

func set_next_active_character(ac, bring_back = false): #step 2
	emit_signal("changed_leader", ac)
	if not bring_back:
		set_active_character(ac)

func set_active_character(ac): #step 3
#	turn_label.text = "Turn: " + active_character.team
	if not ac_ref.get_ref():
		choose_next_active_character(true)
	if ac.is_bot:
		var opposing_team
		var opposing_character = null
		match active_character.team:
			"Blue":
				#look for opposing in red
				opposing_team = $RedTeam
			"Red":
				#look for opposing in blue
				opposing_team = $BlueTeam
		for child in opposing_team.get_children():
			if opposing_character == null or child.global_position.distance_to(active_character.global_position) < opposing_character.global_position.distance_to(active_character.global_position):
				opposing_character = child
		active_character.opposing_character = opposing_character
		#TODO look for closest enemy and put in opposing_character
	ac.set_active()

func _on_character_died(character):
	for i in range (teams.size()):
		var x = team_members[i].find(character)
		if x != -1: #ie there it is!
			team_members[i].remove(x)
