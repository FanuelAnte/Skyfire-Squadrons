extends KinematicBody2D

export (bool) var is_player = true
export (Resource) var plane_details

export(NodePath) var target_node

var velocity = Vector2.ZERO
var steer_angle

func _physics_process(delta):
	get_input(delta)
	velocity = move_and_slide(velocity)

func get_input(delta):
	var turn = 0
	if is_player:
		if Input.is_action_pressed("turn_right"):
			turn += 1
		elif Input.is_action_pressed("turn_left"):
			turn -= 1
		
		if Input.is_action_pressed("increase_bank"):
			turn *= 1.5
		
	else:
		var target = get_node(target_node)
		$Camera2D.current = false
		var direction = (target.global_position - self.global_position)
		var angle = self.transform.x.angle_to(direction)
		
		turn += sign(stepify(rad2deg(angle), 15)) * 1
#		print(stepify(rad2deg(angle), 15))
		
		
	steer_angle = turn * deg2rad(plane_details.bank_angle)
	velocity = Vector2.ZERO
	velocity = transform.x * plane_details.speed
	
	var rear_wheel = position - transform.x * plane_details.wingspan / 2.0
	var front_wheel = position + transform.x * plane_details.wingspan / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	rotation = new_heading.angle()
