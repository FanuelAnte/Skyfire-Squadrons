extends Area2D

var smoke_scene = preload("res://Scenes/SmokeParticles.tscn")
onready var dodge_timer = $"%DodgeTimer"

export (NodePath) var HealthComponentPath
var health_component
var camera_component

var plane_body

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	plane_body = get_parent()
	health_component = get_node(HealthComponentPath)
	camera_component =  plane_body.get_node(plane_body.camera_component)
	
func _physics_process(delta):
	pass

func damage_smoke(hit_position):
	var smoke = smoke_scene.instance()
	get_parent().add_child(smoke)
	smoke.emitting = true
	smoke.global_position = hit_position

func _on_HurtboxComponent_area_entered(area):
	if area.is_in_group("bullet") and !plane_body.is_dead:
		if area.who_shot_me != plane_body:
			var damage = area.damage
#			damage_smoke(area.global_position)
			area.queue_free()
			health_component.take_damage(damage)
			yield(get_tree().create_timer(stepify(rng.randf_range(0, 0.2), 0.1)), "timeout")
			plane_body.is_being_shot = true
			dodge_timer.start(stepify(rng.randf_range(0.5, plane_body.pilot.dodge_duration), 0.1))
			
			if plane_body.is_player:
				camera_component.camera_shake(0.5, 3)
				
				if OS.get_name() == "Android":
					Input.vibrate_handheld(40)

func _on_Timer_timeout():
	plane_body.is_being_shot = false
	plane_body.get_node(plane_body.movement_component).evade_direction *= -1
