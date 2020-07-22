extends CanvasLayer

onready var container = $CenterContainer
onready var rect = $ColorRect
onready var anim = $AnimationPlayer
func _ready():
	container.modulate.a = 0.0
	rect.modulate.a = 0.0
func show():
	anim.play("show")
