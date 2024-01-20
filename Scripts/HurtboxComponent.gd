extends Area2D

var smoke_scene = preload("res://Scenes/SmokeParticles.tscn")

export (NodePath) var HealthComponentPath
var health_component

func _ready():
	health_component = get_node(HealthComponentPath)

func _physics_process(delta):
	pass

func damage_smoke(hit_position):
	var smoke = smoke_scene.instance()
	get_parent().add_child(smoke)
	smoke.emitting = true
	smoke.global_position = hit_position

func _on_HurtboxComponent_area_entered(area):
	if area.is_in_group("bullet"):
		var damage = area.weapon_details.damage
#		damage_smoke(area.global_position)
		area.queue_free()
		health_component.take_damage(damage)
