extends Node2D

export (PackedScene) var primary_weapon
export (PackedScene) var secondary_weapon
export (PackedScene) var tertiary_weapon

var plane_body

func _ready():
	plane_body = get_parent()

func _physics_process(delta):
	get_input()
	
func get_input():
	if plane_body.is_player:
		if Input.is_action_just_pressed("fire_primary"):
#			yield(get_tree().create_timer(stepify(rand_range(0.1, 0.2), 0.1)), "timeout")
			spawn_bullet(primary_weapon, 0)
		
		if Input.is_action_just_pressed("fire_secondary"):
			pass
			
		if Input.is_action_just_pressed("fire_tertiary"):
			pass
			
func spawn_bullet(bullet_path, weapon_group):
	for muzzle in get_child(weapon_group).get_children():
		var bullet = bullet_path.instance()
		get_parent().get_parent().add_child(bullet)
		bullet.transform = muzzle.global_transform
		
