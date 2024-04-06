extends Node2D

var plane_body
var camera

var zoom_max = 1
var zoom_min = 3

func _ready():
	plane_body = get_parent()
	camera = get_child(0)
	
	if plane_body.is_player:
		camera.current = true
		
func _process(delta):
	if plane_body.is_player and !plane_body.is_dead:
		get_input()
	
func get_input():
	if Input.is_action_just_pressed("zoom_max"):
		tween_camera_zoom(Vector2(1, 1) * lerp(zoom_min, zoom_max, 0))

	if Input.is_action_just_pressed("zoom_four"):
		tween_camera_zoom(Vector2(1, 1) * lerp(zoom_min, zoom_max, 0.25))
		
	if Input.is_action_just_pressed("zoom_mid"):
		tween_camera_zoom(Vector2(1, 1) * lerp(zoom_min, zoom_max, 0.5))
		
	if Input.is_action_just_pressed("zoom_two"):
		tween_camera_zoom(Vector2(1, 1) * lerp(zoom_min, zoom_max, 0.75))
		
	if Input.is_action_just_pressed("zoom_min"):
		tween_camera_zoom(Vector2(1, 1) * lerp(zoom_min, zoom_max, 1))
		
func move_camera(amount):
	camera.offset = Vector2(rand_range(-amount.x, amount.x), rand_range(-amount.y, amount.y))
		
func camera_shake(length, power):
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(self, "move_camera", Vector2(power, power), Vector2(0, 0), length)
		
func tween_camera_zoom(zoom_level):
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", zoom_level, 0.5)
