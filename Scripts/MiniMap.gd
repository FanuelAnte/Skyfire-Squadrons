extends MarginContainer

onready var radar_icon_enemy = $"%RadarIconEnemy"
onready var radar_icon_ally = $"%RadarIconAlly"
onready var grid = $"%Grid"
onready var icons_controller = $"%Icons"
onready var timer = $"%Timer"

export var zoom = 10
var player

onready var icons = {"ally": radar_icon_ally, "enemy": radar_icon_enemy}

var grid_scale
var markers = {}

func _ready():
	grid_scale = grid.rect_size / (get_viewport_rect().size * zoom)
	player = get_parent().get_parent().get_parent()
	
	update_planes_list()
	
func update_planes_list():
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	for icon in icons_controller.get_children():
		icon.queue_free()
	
	for object in map_objects:
		if !object.is_dead:
			if player.details.alignment != object.details.alignment:
				var new_marker = icons["enemy"].duplicate()
				icons_controller.add_child(new_marker)
				new_marker.show()
				markers[object] = new_marker
			elif player.details.alignment == object.details.alignment:
				var new_marker = icons["ally"].duplicate()
				icons_controller.add_child(new_marker)
				new_marker.show()
				markers[object] = new_marker
	
func _on_Timer_timeout():
	if !player.is_dead:
		if !player:
			return
		
		update_planes_list()
		
		for marker in markers:
			if !marker.is_dead:
				var object_position = (marker.position - player.position) * grid_scale + grid.rect_size / 2
				object_position.x = clamp(object_position.x, 4, grid.rect_size.x - 4)
				object_position.y = clamp(object_position.y, 4, grid.rect_size.y - 4)
				markers[marker].position = object_position
