extends Node2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")

export (Resource) var primary_weapon
export (Resource) var secondary_weapon
export (Resource) var tertiary_weapon

var plane_body
var last_shot_time = 0.0

var primary_ammo_count = 0
var secondary_ammo_count = 0
var tertiary_ammo_count = 0

func _ready():
	plane_body = get_parent()
	primary_ammo_count = primary_weapon.max_ammo_count

func _physics_process(delta):
	get_input()
	
func get_input():
	if plane_body.is_player:
		if Input.is_action_pressed("fire_primary"):
			if OS.get_ticks_msec() - last_shot_time > 50:
				spawn_bullet(primary_weapon, 0)
				primary_ammo_count -= 2
				last_shot_time = OS.get_ticks_msec()
				
		if Input.is_action_just_pressed("fire_secondary"):
			pass
			
		if Input.is_action_just_pressed("fire_tertiary"):
			pass
			
func spawn_bullet(bullet_resource, weapon_group):
	for muzzle in get_child(weapon_group).get_children():
		var bullet = bullet_scene.instance()
		bullet.weapon_details = bullet_resource
		get_parent().get_parent().add_child(bullet)
		bullet.transform = muzzle.global_transform
		
		if OS.get_name() == "Android":
			Input.vibrate_handheld(20)
		
