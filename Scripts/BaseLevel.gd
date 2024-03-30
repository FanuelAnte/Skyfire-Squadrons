extends Node2D

onready var clouds_1 = $"%Clouds1"
onready var clouds_2 = $"%Clouds2"

onready var background = $"%Background"
var payloads = []

func _ready():
	payloads = get_tree().get_nodes_in_group("payloads")
	
	var step_size = (0.35 - 0.2) / 14.0
	
	for i in range(15):
		var step = stepify((0.2 + i * step_size), 0.0001)
		var parallax_layer = ParallaxLayer.new()
		
		parallax_layer.name = "layer" + str(i + 1)
		parallax_layer.motion_scale = Vector2(step, step)
		parallax_layer.add_to_group("payload_layers")
		
		background.add_child(parallax_layer)
	
	background.move_child(clouds_1, background.get_child_count() - 1)
	background.move_child(clouds_2, background.get_child_count() - 1)
	
	#replace the animation player with a timer.
#	payloads[0].animation_player.connect("animation_finished", self, "change_layers")
#	payloads[0].timer.connect("timeout", self, "change_layers", [payloads[0]])
		
func create_payload(payload, plane_position):
	payload.start_position = plane_position
	
	var top_layer = get_tree().get_nodes_in_group("payload_layers")[-1]
	top_layer.add_child(payload)

	payload.position = payload.start_position * top_layer.motion_scale.x	
	payload.timer.connect("timeout", self, "change_layers", [payload])
	
func change_layers(payload):
	var payload_parent = payload.get_parent()
	
#	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
#	tween.tween_property(payload, "position", payload.start_position * payload_parent.motion_scale.x, 0.1)
	
	if payload.current_layer > 1:
		payload_parent.remove_child(payload)
		var layer = get_tree().get_nodes_in_group("payload_layers")[payload.current_layer - 2]
		
		layer.add_child(payload)
		payload.position = payload.start_position * layer.motion_scale.x
		
		payload.current_layer -= 1
	else:
		payload.position = payload.start_position * payload_parent.motion_scale.x
