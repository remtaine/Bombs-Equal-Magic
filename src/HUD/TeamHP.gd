extends TextureProgress

export var team_color := Color()
export var team_name = "Blue Team"
onready var team_hp_label = $TeamHPLabel
onready var tween = $Tween

func _ready():
	tint_progress = team_color
	team_hp_label.text = team_name
#	set_inactive()

func take_damage(dmg):
	value -= dmg
#	tween.interpolate_property(self, "value",value, value-dmg,2.0, Tween.TRANS_LINEAR,Tween.EASE_IN)
#	tween.start()
