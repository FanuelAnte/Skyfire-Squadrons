extends Area2D

onready var icon = $"%Icon"
onready var timer = $"%Timer"

var start_position = Vector2.ZERO

var current_layer = 25

func _ready():
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(icon, "scale", Vector2(0.05, 0.05), timer.wait_time * current_layer)
	
