extends Node2D

onready var consciousness_timer = $"%CTimer"
onready var search_target_timer = $"%SearchTargetTimer"
onready var idle_flight_timer = $"%IdleFlightTimer"
onready var dodge_timer = $"%DodgeTimer"
onready var swerve_timer = $"%SwerveTimer"

var plane_body

var velocity = Vector2.ZERO
var steer_angle
var target_angle_difference = 0

var turn = 0

var can_search = false
var is_chasing = false
var is_idle = true

var fuel = 0
var fuel_critical = false
var fuel_burn_rate_standard = 0
var fuel_burn_rate_max = 0
var total_flight_time
var coasting_duration_seconds

var is_being_shot = false
var is_swerving = false

var is_coasting = true

var full_throttle = false

var drag_start_position = Vector2.ZERO
var current_drag_position = Vector2.ZERO
var drag_distance = 0
var is_dragging = false
var events = {}

# Move game-play setting values to a Settings Globals autoload. This extends to things such as controller and visual modifications.
var drag_values = {
	"lower_limit": 5,
	"upper_limit": 45,
	"max_limit": 50
}

var level_extents = Vector2.ZERO

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

var distance_to_target = null

var turning = false

var enemy_planes = []
var rng = RandomNumberGenerator.new()

var steer_delay_value = 0
var steer_delay_target = 1
var steer_delay_increase_duration = 0.5  
var steer_delay_decrease_duration = 0.1  

func _ready():
	rng.randomize()
	plane_body = get_parent()
	
	speed = plane_body.details.cruise_speed
	fuel = plane_body.details.max_fuel
	coasting_duration_seconds = plane_body.details.coasting_duration_seconds
	fuel_burn_rate_standard = plane_body.details.fuel_burn_rate_standard
	fuel_burn_rate_max = plane_body.details.fuel_burn_rate_max
	
	search_target_timer.wait_time = plane_body.pilot.search_timer_duration
	
	g_force_increase_rate = plane_body.details.g_force_increase_rate
	g_force_decrease_rate = plane_body.details.g_force_decrease_rate
	
	base_g_force_turn_factor = plane_body.details.base_g_force_turn_factor
	max_g_force_turn_factor = plane_body.details.max_g_force_turn_factor
	g_force_throttle_factor = plane_body.details.g_force_throttle_factor
	
	update_enemy_planes()
	
func _process(delta):
	if !plane_body.is_dead:
		get_input(delta)
		apply_rotation(delta)
		velocity = plane_body.move_and_slide(velocity)
		
		if fuel <= plane_body.details.max_fuel/3:
			fuel_critical = true
		
		if full_throttle:
			burn_fuel(fuel_burn_rate_max, delta)
			speed = plane_body.details.max_speed
		elif !full_throttle:
			if fuel > 0:
				is_coasting = false
				burn_fuel(fuel_burn_rate_standard, delta) 
				speed = plane_body.details.cruise_speed
			else:
				if speed >= plane_body.details.cruise_speed:
					is_coasting = true
					var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tween.tween_property(self, "speed", plane_body.details.coasting_speed, coasting_duration_seconds)
					
		if g_force > 1 and g_force_increase_factor == 0:
			g_force -= g_force_decrease_rate * delta
		
		if g_force < 10:
			g_force += g_force_increase_rate * g_force_increase_factor * delta
			
		if g_force >= 10:
			if consciousness > 0:
				consciousness -= plane_body.pilot.unconsciousness_rate * delta
			else:
				consciousness_timer.start(plane_body.pilot.unconsciousness_duration)
				conscious = false
				full_throttle = false
		else:
			if consciousness <= 10 and conscious:
				consciousness += plane_body.pilot.consciousness_rate * delta
		
func burn_fuel(burn_rate, delta):
	if fuel > 0:
		fuel -= burn_rate * delta
	
	var flight_time_seconds = int(stepify((fuel / burn_rate), 1))
	
	var hours = int(flight_time_seconds / 3600)
	var minutes = int((flight_time_seconds % 3600) / 60)
	var seconds = int(flight_time_seconds % 60)
	
	total_flight_time = str(hours).pad_zeros(2) + ":" + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	
func update_enemy_planes():
	enemy_planes = []
	var all_planes = get_tree().get_nodes_in_group("planes_container")[0].get_children()
	for plane in all_planes:
		var plane_position = plane.global_position
		
		var direction = (plane_position - plane_body.global_position)
		var angle = plane_body.transform.x.angle_to(direction)
		
		var angle_difference = stepify(rad2deg(angle), 5)
		
		if plane.details.alignment != plane_body.details.alignment and !plane.is_dead and angle_difference < plane_body.pilot.max_turn_threshold and !plane.targeted:
			enemy_planes.append(plane)
		
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < int(get_viewport_rect().size.x/2):
				Input.vibrate_handheld(60)
# 				The following line fixes the start position to center of the left third of the screen. Make it an in-game control option.
#				drag_start_position = Vector2((get_viewport_rect().size.x/3)/2, event.position.y)
				drag_start_position = event.position
			else:
				if !is_dragging:
					drag_start_position = null
		else:
			events.erase(event.index)
			
	if event is InputEventScreenDrag:
		events[event.index] = event
		if drag_start_position != null and event.position.x < int(get_viewport_rect().size.x/2):
			current_drag_position = event.position
			drag_distance = clamp((drag_start_position - event.position).x * -1, -drag_values["max_limit"], drag_values["max_limit"])
		
	if events.size() == 0:
		is_dragging = false
		drag_distance = 0
	else:
		is_dragging = true
		
func get_input(delta):
	turning = false
	turn = 0
	g_force_increase_factor = 0
	full_throttle = false
	
	if plane_body.is_player and conscious:
#		Maybe optimize this by checking the difference between left and right inputs
		
#		Analogue vs digital.
#		var drag_clampped_min = range_lerp(abs(drag_distance), drag_values["lower_limit"], drag_values["upper_limit"], 0, 1)
		var drag_clampped_min = 1
		if Input.is_action_pressed("turn_right") or (drag_distance > drag_values["lower_limit"] and drag_distance < drag_values["upper_limit"] and is_dragging):
			steer_delay_value = lerp(steer_delay_value, steer_delay_target, delta / steer_delay_increase_duration)
			
			if is_dragging:
				turn += 1 * drag_clampped_min * stepify(steer_delay_value, 0.1)
			else:
				turn += 1 * stepify(steer_delay_value, 0.1)
			
			if !is_coasting:
				g_force_increase_factor += base_g_force_turn_factor
				
			turning = true
			
		elif Input.is_action_pressed("turn_left") or (drag_distance < -drag_values["lower_limit"] and drag_distance > -drag_values["upper_limit"] and is_dragging):
			steer_delay_value = lerp(steer_delay_value, steer_delay_target, delta / steer_delay_increase_duration)
			
			if is_dragging:
				turn -= 1 * drag_clampped_min * stepify(steer_delay_value, 0.1)
			else:
				turn -= 1 * stepify(steer_delay_value, 0.1)
				
			if !is_coasting:
				g_force_increase_factor += base_g_force_turn_factor
			
			turning = true
			
		if Input.is_action_pressed("throttle"):
			if fuel > 0:
				full_throttle = true
				g_force_increase_factor += g_force_throttle_factor
			
		if Input.is_action_pressed("increase_bank") and turning:
			turn *= plane_body.details.max_bank_angle_factor
			if is_coasting:
				g_force_increase_factor += base_g_force_turn_factor
			else:
				g_force_increase_factor += max_g_force_turn_factor
		
#		this part is used by the mobile touch inputs.
#		Analogue bs digital.
#		var drag_clampped_max = clamp(range_lerp(abs(drag_distance), drag_values["upper_limit"], drag_values["max_limit"], 0, 1), 0, 1)
		var drag_clampped_max = 1
		if Input.is_action_pressed("turn_right_max") or (drag_distance >= drag_values["upper_limit"] and drag_distance <= drag_values["max_limit"] and is_dragging):
			steer_delay_value = lerp(steer_delay_value, steer_delay_target, delta / steer_delay_increase_duration)
			
			if is_dragging:
				turn += 1 * plane_body.details.max_bank_angle_factor * drag_clampped_max * stepify(steer_delay_value, 0.1)
			else:
				turn += 1 * plane_body.details.max_bank_angle_factor * stepify(steer_delay_value, 0.1)
				
			if is_coasting:
				g_force_increase_factor += base_g_force_turn_factor
			else:
				g_force_increase_factor += max_g_force_turn_factor
			
			turning = true
			
		elif Input.is_action_pressed("turn_left_max") or (drag_distance <= -drag_values["upper_limit"] and drag_distance <= drag_values["max_limit"] and is_dragging):
			steer_delay_value = lerp(steer_delay_value, steer_delay_target, delta / steer_delay_increase_duration)
			
			if is_dragging:
				turn -= 1 * plane_body.details.max_bank_angle_factor * drag_clampped_max * stepify(steer_delay_value, 0.1)
			else:
				turn -= 1 * plane_body.details.max_bank_angle_factor * stepify(steer_delay_value, 0.1)
				
			if is_coasting:
				g_force_increase_factor += base_g_force_turn_factor
			else:
				g_force_increase_factor += max_g_force_turn_factor
			
			turning = true
			
		if !turning:
			steer_delay_value = lerp(steer_delay_value, 0, delta / steer_delay_decrease_duration)
			
	elif !plane_body.is_player and conscious:
		if !is_being_shot and !is_swerving:
			var target_point = Vector2(0, 0)
			
			if plane_body.target_node != "":
				var target = plane_body.get_parent().get_node(plane_body.target_node)
				
				distance_to_target = plane_body.global_position.distance_to(target.global_position)
				
				target_point = target.global_position
				is_chasing = true
			else:
				if !can_search:
					if enemy_planes.size() > 1:
						var target_one = enemy_planes[0]
						var target_two = enemy_planes[1]
						target_point = Vector2((target_one.global_position.x + target_two.global_position.x) / 2, (target_one.global_position.y + target_two.global_position.y) / 2)
					elif enemy_planes.size() == 1:
						var target_one = enemy_planes[0]
						target_point = target_one.global_position
					else:
						target_point = Vector2(0, 0)
					
				else:
					can_search = false
					var value = rng.randi_range(0, 1)
					if value == 1 and !is_idle:
						if enemy_planes.size() != 0:
							var picked_target = enemy_planes[rng.randi_range(0, enemy_planes.size() - 1)]
							plane_body.target_node = picked_target.name
							picked_target.targeted = true
							is_chasing = true
							
			if !is_idle:
				var direction = (target_point - plane_body.global_position)
				var angle = plane_body.transform.x.angle_to(direction)
				
				target_angle_difference = stepify(rad2deg(angle), 5)
				
				if is_chasing:
					if abs(target_angle_difference) <= plane_body.pilot.min_turn_threshold:
						turn += sign(target_angle_difference) * 1
						
						if !is_coasting:
							g_force_increase_factor += base_g_force_turn_factor
							
					elif abs(target_angle_difference) > plane_body.pilot.min_turn_threshold and abs(target_angle_difference) <= plane_body.pilot.max_turn_threshold:
						turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
						
						if is_coasting:
							g_force_increase_factor += base_g_force_turn_factor
						else:
							g_force_increase_factor += max_g_force_turn_factor
							
					else:
						reset_targeting(false)
					
					if distance_to_target != null and distance_to_target < 48:
						reset_targeting(true)
					
				else:
					if abs(target_angle_difference) <= plane_body.pilot.min_turn_threshold:
						turn += sign(target_angle_difference) * 1
						
						if !is_coasting:
							g_force_increase_factor += base_g_force_turn_factor
							
					elif abs(target_angle_difference) > plane_body.pilot.min_turn_threshold:
						turn += sign(target_angle_difference) * plane_body.details.max_bank_angle_factor
						
						if is_coasting:
							g_force_increase_factor += base_g_force_turn_factor
						else:
							g_force_increase_factor += max_g_force_turn_factor
							
		else:
			turn += 1 * evade_direction
			g_force_increase_factor += base_g_force_turn_factor
			
#			if is_coasting:
#				g_force_increase_factor += base_g_force_turn_factor
#			else:
#				g_force_increase_factor += max_g_force_turn_factor
			
	steer_angle = turn * deg2rad(plane_body.details.bank_angle)
	velocity = Vector2.ZERO
	velocity = plane_body.transform.x * speed

func reset_targeting(should_swerve):
	if plane_body.target_node != "":
		plane_body.get_parent().get_node(plane_body.target_node).targeted = false
		plane_body.target_node = ""
		
	can_search = false
	is_chasing = false
	distance_to_target = null
	
	if should_swerve:
		is_swerving = true
		swerve_timer.start(stepify(rng.randf_range(0.5, plane_body.pilot.swerve_duration), 0.1))
	
	if !is_idle:
		is_idle = true
		idle_flight_timer.start(rng.randi_range(5, 10))

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

func _on_SearchTargetTimer_timeout():
	can_search = true

func _on_UpdateEnemiesTimer_timeout():
	update_enemy_planes()
	
func _on_IdleFlightTimer_timeout():
	is_idle = false

func _on_DodgeTimer_timeout():
	is_being_shot = false
	evade_direction *= -1

func _on_SwerveTimer_timeout():
	is_swerving = false
	evade_direction *= -1
	
