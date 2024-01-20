extends Node2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")

export (Resource) var primary_weapon
export (Resource) var secondary_weapon
export (Resource) var tertiary_weapon

var plane_body
var primary_last_shot_time = 0.0

var primary_ammo_count = 0
var secondary_ammo_count = 0
var tertiary_ammo_count = 0

var primary_is_overheated = false
var primary_heat = 0

func _ready():
	plane_body = get_parent()
	primary_ammo_count = primary_weapon.max_ammo_count

func _physics_process(delta):
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
	
func get_input():
	if plane_body.is_player:
		if Input.is_action_pressed("fire_primary") and !primary_is_overheated:
			shoot_primary()
			
		if Input.is_action_just_pressed("fire_secondary"):
			self.queue_free()
			
		if Input.is_action_just_pressed("fire_tertiary"):
			pass
			
	else:
		if plane_body.target_node != "" and !primary_is_overheated:
			var movement_component = plane_body.get_node(plane_body.movement_component)
			if abs(movement_component.target_angle_difference) < 20 and movement_component.can_shoot:
				shoot_primary()

func shoot_primary():
	if OS.get_ticks_msec() - primary_last_shot_time > primary_weapon.delay_between_shots:
		spawn_bullet(primary_weapon, 0)
		primary_ammo_count -= 2
		primary_last_shot_time = OS.get_ticks_msec()
		
		primary_heat += primary_weapon.heating_rate
		
func spawn_bullet(bullet_resource, weapon_group):
	for muzzle in get_child(weapon_group).get_children():
		var bullet = bullet_scene.instance()
		bullet.weapon_details = bullet_resource
		get_tree().root.get_node("MainGame").get_node("Bullets").add_child(bullet)
		bullet.transform = muzzle.global_transform
		
		if OS.get_name() == "Android" and plane_body.is_player:
			Input.vibrate_handheld(20)
