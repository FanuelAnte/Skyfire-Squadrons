extends Area2D

export (NodePath) var HealthComponentPath
var health_component

func _ready():
	health_component = get_node(HealthComponentPath)

func _physics_process(delta):
	pass

func _on_HurtboxComponent_area_entered(area):
	if area.is_in_group("bullet"):
		var damage = area.weapon_details.damage
		area.queue_free()
		health_component.take_damage(damage)
