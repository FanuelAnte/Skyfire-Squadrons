extends Node2D

var payloads = []

func _ready():
	payloads = get_tree().get_nodes_in_group("payloads")
	
	#replace the animation player with a timer.
	payloads[0].animation_player.connect("animation_finished", self, "change_layers")
	
func change_layers(anim_name):
	var payload_parent = payloads[0].get_parent()
	
	if payloads[0].current_layer > 1:
		payload_parent.remove_child(payloads[0])
		var layer = get_tree().get_nodes_in_group("payload_layers")[payloads[0].current_layer - 2]
	
		layer.add_child(payloads[0])
#		payloads[0].global_position /= layer.motion_scale
		payloads[0].icon.scale = layer.motion_scale
		
		payloads[0].current_layer -= 1
		payloads[0].animation_player.play("shrink")
