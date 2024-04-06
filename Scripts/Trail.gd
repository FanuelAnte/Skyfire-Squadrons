extends Line2D

export (bool) var is_active = true
export (int) var max_trail_length = 5
var point

func _ready():
	set_as_toplevel(true)
	
func _physics_process(delta):
	if is_active:
		point = get_parent().global_position
		add_point(point)
		if points.size() > max_trail_length:
			remove_point(0)
