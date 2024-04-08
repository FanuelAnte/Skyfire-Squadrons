extends Node2D

var bullet_scene = preload("res://Scenes/Weapons/Bullet.tscn")
var payload_scene = preload("res://Scenes/Weapons/Payload.tscn")

export (Resource) var primary_weapon
export (Resource) var secondary_weapon
export (Resource) var tertiary_weapon

var plane_body
var primary_last_shot_time = 0.0
var secondary_last_shot_time = 0.0
var tertiary_last_shot_time = 0.0

var primary_ammo_count = 0
var secondary_ammo_count = 0
var tertiary_ammo_count = 0

var primary_is_overheated = false
var primary_heat = 0

var secondary_is_overheated = false
var secondary_heat = 0

var primary_rays = []
var secondary_rays = []

var can_shoot_primary = false
var can_shoot_secondary = false

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	plane_body = get_parent()
	primary_ammo_count = plane_body.details.max_primary_ammo_count
	secondary_ammo_count = plane_body.details.max_secondary_ammo_count
	tertiary_ammo_count = plane_body.details.max_tertiary_ammo_count
	
	get_rays()
	
func get_rays():
	var rays = get_tree().get_nodes_in_group("detection_rays")
	
	for ray in rays:
		if ray.get_parent().get_parent().get_parent().get_parent() == plane_body:
			if ray.get_parent().get_parent().name == "Primary":
				ray.cast_to = Vector2(primary_weapon.effective_range, 0)
				primary_rays.append(ray)
			elif ray.get_parent().get_parent().name == "Secondary":
				ray.cast_to = Vector2(secondary_weapon.effective_range, 0)
				secondary_rays.append(ray)
				
func _process(delta):
#	pass
	if plane_body.get_node(plane_body.movement_component).conscious:
		get_input()

	if primary_heat >= primary_weapon.max_heat:
		primary_is_overheated = true

	elif primary_heat > 0:
		primary_heat -= primary_weapon.cooling_rate * delta

	if primary_is_overheated:
		if primary_heat > primary_weapon.heat_threshold:
			primary_heat -= primary_weapon.cooling_rate * delta
		else:
			primary_is_overheated = false

	if secondary_heat >= secondary_weapon.max_heat:
		secondary_is_overheated = true

	elif secondary_heat > 0:
		secondary_heat -= secondary_weapon.cooling_rate * delta

	if secondary_is_overheated:
		if secondary_heat > secondary_weapon.heat_threshold:
			secondary_heat -= secondary_weapon.cooling_rate * delta
		else:
			secondary_is_overheated = false
	
func get_input():
	if !plane_body.is_dead:
		if plane_body.is_player:
			if Input.is_action_pressed("fire_primary") and !primary_is_overheated:
				shoot_primary()
				
			if Input.is_action_pressed("fire_secondary") and !secondary_is_overheated:
				shoot_secondary()
				
			if Input.is_action_just_pressed("fire_tertiary"):
				release_payload()
				
		else:
			check_rays()
			if can_shoot_primary and !primary_is_overheated:
				shoot_primary()
			if can_shoot_secondary and !primary_is_overheated:
				shoot_secondary()
		
func check_rays():
	for ray in primary_rays:
		ray.force_raycast_update()
		if ray.is_colliding():
			if ray.get_collider().get_parent().details.alignment != plane_body.details.alignment and !ray.get_collider().get_parent().is_dead:
				can_shoot_primary = true
				break
		else:
			can_shoot_primary = false
			
	for ray in secondary_rays:
		ray.force_raycast_update()
		if ray.is_colliding():
			if ray.get_collider().get_parent().details.alignment != plane_body.details.alignment and !ray.get_collider().get_parent().is_dead:
				can_shoot_secondary = true
				break
		else:
			can_shoot_secondary = false
			
func shoot_primary():
	if primary_ammo_count > 0:
		if OS.get_ticks_msec() - primary_last_shot_time > primary_weapon.delay_between_shots:
			spawn_bullet(primary_weapon, 0)
			primary_ammo_count -= get_child(0).get_child_count()
			primary_last_shot_time = OS.get_ticks_msec()
			
			primary_heat += primary_weapon.heating_rate
		
func shoot_secondary():
	if secondary_ammo_count > 0:
		if OS.get_ticks_msec() - secondary_last_shot_time > secondary_weapon.delay_between_shots:
			spawn_bullet(secondary_weapon, 1)
			secondary_ammo_count -= get_child(1).get_child_count()
			secondary_last_shot_time = OS.get_ticks_msec()
			
			secondary_heat += secondary_weapon.heating_rate
		
func release_payload():
	if tertiary_ammo_count > 0:
		if OS.get_ticks_msec() - tertiary_last_shot_time > tertiary_weapon.delay_between_drops:
			spawn_payload(tertiary_weapon, 2)
			tertiary_ammo_count -= get_child(2).get_child_count()
			tertiary_last_shot_time = OS.get_ticks_msec()
			
func spawn_bullet(bullet_resource, weapon_group):
	for muzzle in get_child(weapon_group).get_children():
		var bullet = bullet_scene.instance()
		bullet.weapon_details = bullet_resource
		bullet.who_shot_me = plane_body
		get_tree().get_nodes_in_group("bullets_container")[0].add_child(bullet)
		bullet.transform = muzzle.global_transform
		
		if OS.get_name() == "Android" and plane_body.is_player:
			Input.vibrate_handheld(30)

func spawn_payload(payload_res, weapon_group):
	for bay in get_child(weapon_group).get_children():
		var payload = payload_scene.instance()
		payload.payload_details = payload_res
		payload.transform = bay.global_transform
		
		get_tree().get_nodes_in_group("levels")[0].create_payload(payload, plane_body.position)
		
		if OS.get_name() == "Android" and plane_body.is_player:
			Input.vibrate_handheld(50)
