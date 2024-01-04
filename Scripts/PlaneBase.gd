extends KinematicBody2D


var wheel_base = 70
var steering_angle = 10

var velocity = Vector2.ZERO
var steer_angle

var speed = 500

func _ready():
	pass

func _physics_process(delta):
	get_input(delta)
	velocity = move_and_slide(velocity)

func get_input(delta):
	var turn = 0
	if Input.is_action_pressed("turn_right"):
		turn += 1
	elif Input.is_action_pressed("turn_left"):
		turn -= 1
	
	if Input.is_action_pressed("increase_bank"):
		turn *= 1.5
	
	steer_angle = turn * deg2rad(steering_angle)
	velocity = Vector2.ZERO
	velocity = transform.x * speed

	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	rotation = new_heading.angle()
