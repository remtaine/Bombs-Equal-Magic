extends Sprite

onready var destructible = $Destructible
onready var bg_sprite = $BGSprite

func _ready():
	pass
#	bg_sprite.texture = texture	

func destroy(pos, radius):
	destructible.destroy(pos, radius)
