extends Node2D

export (NodePath) var plane_path
var plane_body

var velocity = Vector2.ZERO
var steer_angle

func _ready():
#	if plane_path != null:
	plane_body = get_parent()

func _physics_process(delta):
	get_input()
	apply_rotation(delta)
	velocity = plane_body.move_and_slide(velocity)

func get_input():
	var turn = 0
	if plane_body.is_player:
		if Input.is_action_pressed("turn_right"):
			turn += 1
		elif Input.is_action_pressed("turn_left"):
			turn -= 1

		if Input.is_action_pressed("increase_bank"):
			turn *= plane_body.details.max_bank_angle_factor

	else:
		var target = plane_body.get_node(plane_body.target_node)
		plane_body.camera.current = false
		var direction = (target.global_position - plane_body.global_position)
		var angle = plane_body.transform.x.angle_to(direction)

		var snapped_angle = stepify(rad2deg(angle), 15)

		if abs(snapped_angle) <= 90:
			turn += sign(snapped_angle) * 1
		else:
			turn += sign(snapped_angle) * plane_body.details.max_bank_angle_factor

	steer_angle = turn * deg2rad(plane_body.details.bank_angle)
	velocity = Vector2.ZERO
	velocity = plane_body.transform.x * plane_body.details.speed

func apply_rotation(delta):
	var rear_wheel = plane_body.position - plane_body.transform.x * plane_body.details.wingspan / 2.0
	var front_wheel = plane_body.position + plane_body.transform.x * plane_body.details.wingspan / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	plane_body.rotation = new_heading.angle()
