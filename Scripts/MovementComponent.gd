extends Node2D

onready var ray_1 = $"%Ray1"
onready var ray_2 = $"%Ray2"
onready var ray_3 = $"%Ray3"
onready var ray_4 = $"%Ray4"
onready var ray_5 = $"%Ray5"

var plane_body

var velocity = Vector2.ZERO
var steer_angle
var target_angle_difference = 0

var g_force = 0

var enemy_planes = []

var rays = []

func _ready():
	plane_body = get_parent()
	rays = get_children()
	update_enemy_planes()

func _physics_process(delta):
	get_input()
	apply_rotation(delta)
	velocity = plane_body.move_and_slide(velocity)
	update_enemy_planes()
#	print("-------")
#	print(plane_body.name)
#	print(enemy_planes)
#	print("-------")

func update_enemy_planes():
	enemy_planes = []
	var all_planes = get_tree().root.get_node("MainGame").get_node("Planes").get_children()
	for plane in all_planes:
		if plane.details.alignment != plane_body.details.alignment and !plane.targeted:
			enemy_planes.append(plane.name)

func get_input():
	var turn = 0
	if plane_body.is_player:
		plane_body.camera.current = true
		if Input.is_action_pressed("turn_right"):
			turn += 1
		elif Input.is_action_pressed("turn_left"):
			turn -= 1

		if Input.is_action_pressed("increase_bank"):
			turn *= plane_body.details.max_bank_angle_factor
		
		if Input.is_action_pressed("turn_right_max"):
			turn += 1 * plane_body.details.max_bank_angle_factor
		elif Input.is_action_pressed("turn_left_max"):
			turn -= 1 * plane_body.details.max_bank_angle_factor
		
	else:
		# TODO: Figure out a way to share the movement code between the serch state and the target state.
		
		if plane_body.target_node != "":
			var target = plane_body.get_parent().get_node(plane_body.target_node)
			var direction = (target.global_position - plane_body.global_position)
			var angle = plane_body.transform.x.angle_to(direction)
			
			target_angle_difference = stepify(rad2deg(angle), 5)
			
			if abs(target_angle_difference) <= 90:
				turn += sign(target_angle_difference) * 1
			elif abs(target_angle_difference) >= 90 and abs(target_angle_difference) <= 120:
				turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
			else:
				turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
				target.targeted = false
				plane_body.target_node = ""
				
		else:
			randomize()
			plane_body.target_node = enemy_planes[randi() % enemy_planes.size()]
			var target = plane_body.get_parent().get_node(plane_body.target_node)
			target.targeted = true
#			search_target()
			
	steer_angle = turn * deg2rad(plane_body.details.bank_angle)
	velocity = Vector2.ZERO
	velocity = plane_body.transform.x * plane_body.details.speed

#func search_target():
#	for ray in rays:
#		ray.force_raycast_update()
#		if ray.is_colliding():
#			if ray.get_collider().get_parent().details.alignment != plane_body.details.alignment:
#				plane_body.target_node = ray.get_collider().get_parent().name

func apply_rotation(delta):
	var rear_wheel = plane_body.position - plane_body.transform.x * plane_body.details.wingspan / 2.0
	var front_wheel = plane_body.position + plane_body.transform.x * plane_body.details.wingspan / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	plane_body.rotation = new_heading.angle()
