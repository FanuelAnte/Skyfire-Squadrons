extends Node2D

onready var c_timer = $"%CTimer"

var plane_body

var velocity = Vector2.ZERO
var steer_angle
var target_angle_difference = 0

var turn = 0

var fuel = 0
var fuel_burn_rate_standard = 0
var fuel_burn_rate_max = 0
var total_flight_time
var coasting_duration_seconds

var full_throttle = false

var drag_start_position = Vector2.ZERO
var drag_distance = 0
var	is_dragging = false
var events = {}

var drag_lower_limit = 10
var drag_upper_limit = 110

var curr_f_pos = 0

var speed = 0
var evade_direction = 1

var g_force = 1
var g_force_increase_rate
var g_force_decrease_rate
var g_force_increase_factor

var base_g_force_turn_factor
var max_g_force_turn_factor
var g_force_throttle_factor

var consciousness = 10
var conscious = true

var turning = false

var enemy_planes = []
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	plane_body = get_parent()
	
	speed = plane_body.details.cruise_speed
	coasting_duration_seconds = plane_body.details.coasting_duration_seconds
	fuel = plane_body.details.max_fuel
	fuel_burn_rate_standard = plane_body.details.fuel_burn_rate_standard
	fuel_burn_rate_max = plane_body.details.fuel_burn_rate_max
	
	g_force_increase_rate = plane_body.details.g_force_increase_rate
	g_force_decrease_rate = plane_body.details.g_force_decrease_rate
	
	base_g_force_turn_factor = plane_body.details.base_g_force_turn_factor
	max_g_force_turn_factor = plane_body.details.max_g_force_turn_factor
	g_force_throttle_factor = plane_body.details.g_force_throttle_factor
	
	update_enemy_planes()
	
func _physics_process(delta):
	if !plane_body.is_dead:
		get_input()
		apply_rotation(delta)
		velocity = plane_body.move_and_slide(velocity)
		update_enemy_planes()
		
#		if !is_dragging:
#			drag_start_position = null
	
		if !full_throttle:
			burn_fuel(fuel_burn_rate_standard, delta)
			speed = plane_body.details.cruise_speed
		else:
			burn_fuel(fuel_burn_rate_max, delta)
			speed = plane_body.details.max_speed
		
		if g_force > 1 and g_force_increase_factor == 0:
			g_force -= g_force_decrease_rate * delta
		
		if g_force < 10:
			g_force += g_force_increase_rate * g_force_increase_factor * delta
			
		if g_force >= 10:
			if consciousness > 0:
				consciousness -= plane_body.pilot.unconsciousness_rate * delta
			else:
				c_timer.start(plane_body.pilot.unconsciousness_duration)
				conscious = false
				full_throttle = false
		else:
			if consciousness <= 10 and conscious:
				consciousness += plane_body.pilot.consciousness_rate * delta
			
func burn_fuel(burn_rate, delta):
	if fuel > 0:
		fuel -= burn_rate * delta
		
	var flight_time_seconds = int(stepify((fuel / burn_rate), 1) + coasting_duration_seconds)
	
	var hours = int(flight_time_seconds / 3600)
	var minutes = int((flight_time_seconds % 3600) / 60)
	var seconds = int(flight_time_seconds % 60)
	
	total_flight_time = str(hours).pad_zeros(2) + ":" + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	
func update_enemy_planes():
	enemy_planes = []
	var all_planes = get_tree().root.get_node("MainGame").get_node("Planes").get_children()
	for plane in all_planes:
		if plane.details.alignment != plane_body.details.alignment and !plane.targeted:
			enemy_planes.append(plane)
		
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < int(get_viewport_rect().size.x/3):
				drag_start_position = event.position
			else:
				if !is_dragging:
					drag_start_position = null

		else:
			events.erase(event.index)
			
	if event is InputEventScreenDrag:
		events[event.index] = event
		if drag_start_position != null:
			drag_distance = (drag_start_position - events[0].position).x * -1
			
	curr_f_pos = str(events.keys().size()) + " " + str(drag_distance) + " " + str(is_dragging)
	
	if events.size() == 0:
		is_dragging = false
		drag_distance = 0
	else:
		is_dragging = true
		
func get_input():
	turning = false
	turn = 0
	g_force_increase_factor = 0
	
	if plane_body.is_player and conscious:
		if Input.is_action_pressed("turn_right") or (drag_distance > drag_lower_limit and drag_distance < drag_upper_limit and is_dragging):
			turn += 1
			g_force_increase_factor += base_g_force_turn_factor
			turning = true

		elif Input.is_action_pressed("turn_left") or (drag_distance < -drag_lower_limit and drag_distance > -drag_upper_limit and is_dragging):
			turn -= 1
			g_force_increase_factor += base_g_force_turn_factor
			turning = true

		if full_throttle:
			g_force_increase_factor += g_force_throttle_factor

		if Input.is_action_just_pressed("toggle_throttle"):
			if full_throttle:
				full_throttle = false
			else:
				full_throttle = true

		if Input.is_action_pressed("increase_bank") and turning:
			turn *= plane_body.details.max_bank_angle_factor
			g_force_increase_factor += max_g_force_turn_factor

		if Input.is_action_pressed("turn_right_max") or (drag_distance >= drag_upper_limit and is_dragging):
			turn += 1 * plane_body.details.max_bank_angle_factor
			g_force_increase_factor += g_force_throttle_factor
		elif Input.is_action_pressed("turn_left_max") or (drag_distance <= -drag_upper_limit and is_dragging):
			turn -= 1 * plane_body.details.max_bank_angle_factor
			g_force_increase_factor += g_force_throttle_factor
		
	elif !plane_body.is_player and conscious:
	# Make the detection and targeting logic better.
		if !plane_body.is_being_shot:
			if plane_body.target_node != "":
				var target = plane_body.get_parent().get_node(plane_body.target_node)
				
				if !target.is_dead:
					var direction = (target.global_position - plane_body.global_position)
					var angle = plane_body.transform.x.angle_to(direction)
					
					target_angle_difference = stepify(rad2deg(angle), 5)
					
					if g_force < 8:
						if direction.length() > 300:
							full_throttle = true
						else:
							full_throttle = false
					else:
						full_throttle = false
					
					if abs(target_angle_difference) <= 60:
						turn += sign(target_angle_difference) * 1
						g_force_increase_factor += base_g_force_turn_factor
					elif abs(target_angle_difference) >= 60 and abs(target_angle_difference) <= 150:
						turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
						g_force_increase_factor += max_g_force_turn_factor
					else:
						turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
						g_force_increase_factor += max_g_force_turn_factor
						target.targeted = false
						plane_body.target_node = ""
					
				else:
					turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
					g_force_increase_factor += max_g_force_turn_factor
					plane_body.target_node = ""
				
			else:
				var value = rng.randi_range(0, 5)
				if value == 1:
					if enemy_planes.size() != 0:
						var target = enemy_planes[rng.randi_range(0, enemy_planes.size() - 1)]
						if !target.targeted and !target.is_dead:
							plane_body.target_node = target.name
							target.targeted = true
						
		else:
			turn += plane_body.details.max_bank_angle_factor * evade_direction
			g_force_increase_factor += max_g_force_turn_factor
			
	steer_angle = turn * deg2rad(plane_body.details.bank_angle)
	velocity = Vector2.ZERO
	velocity = plane_body.transform.x * speed

func apply_rotation(delta):
	var rear = plane_body.position - plane_body.transform.x * plane_body.details.wingspan / 2.0
	var front = plane_body.position + plane_body.transform.x * plane_body.details.wingspan / 2.0
	rear += velocity * delta
	front += velocity.rotated(steer_angle) * delta
	var new_heading = (front - rear).normalized()
	velocity = new_heading * velocity.length()
	plane_body.rotation = new_heading.angle()

func _on_CTimer_timeout():
	conscious = true
