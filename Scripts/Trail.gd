extends Line2D

export (int) var max_trail_length = 5
var point

func _ready():
	set_as_toplevel(true)
	
func _process(delta):
	point = get_parent().global_position
	add_point(point)
	if points.size() > max_trail_length:
		remove_point(0)
