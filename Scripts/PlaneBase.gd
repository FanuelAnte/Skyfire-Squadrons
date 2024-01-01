extends KinematicBody2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")
onready var position_2d = $Position2D

var wheel_base = 50
var steering_angle = 15

var velocity = Vector2.ZERO
var steer_angle

var speed = 400

func _ready():
	pass

func _physics_process(delta):
	get_input()
	calculate_steering(delta)
	velocity = move_and_slide(velocity)

func get_input():
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
		
	if Input.is_action_just_pressed("ui_accept"):
		shoot()
		
	steer_angle = turn * deg2rad(steering_angle)
	velocity = Vector2.ZERO
	velocity = transform.x * speed

func shoot():
	var b = bullet_scene.instance()
	owner.add_child(b)
	b.transform = position_2d.global_transform

func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	rotation = new_heading.angle()
