extends Area2D

export (Resource) var payload_details

onready var sprite = $"%Sprite"
onready var timer = $"%Timer"

var start_position = Vector2.ZERO

var current_layer = 20

func _ready():
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(sprite, "scale", Vector2(0.02, 0.02), timer.wait_time * current_layer)
	
func _process(delta):
	pass
