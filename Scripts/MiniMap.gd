extends MarginContainer

onready var radar_icon_enemy = $"%RadarIconEnemy"
onready var radar_icon_ally = $"%RadarIconAlly"
onready var grid = $"%Grid"


export var zoom = 10
var player

onready var icons = {"ally": radar_icon_ally, "enemy": radar_icon_enemy}

var grid_scale
var markers = {}

func _ready():
	grid_scale = grid.rect_size / (get_viewport_rect().size * zoom)
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	
	player = get_parent().get_parent().get_parent()
	
	for object in map_objects:
		if player.details.alignment != object.details.alignment:
			var new_marker = icons["enemy"].duplicate()
			grid.add_child(new_marker)
			new_marker.show()
			markers[object] = new_marker
		elif player.details.alignment == object.details.alignment:
			var new_marker = icons["ally"].duplicate()
			grid.add_child(new_marker)
			new_marker.show()
			markers[object] = new_marker
	
func _process(delta):
	if !player:
		return
	
	for marker in markers:
		var object_position = (marker.position - player.position) * grid_scale + grid.rect_size / 2
		object_position.x = clamp(object_position.x, 4, grid.rect_size.x - 4)
		object_position.y = clamp(object_position.y, 4, grid.rect_size.y - 4)
		markers[marker].position = object_position
