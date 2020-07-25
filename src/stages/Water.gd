extends Sprite

var damage : int = 100
onready var hitbox = $Hitbox

func _ready():
	hitbox.setup(self)
	hitbox.activate()
