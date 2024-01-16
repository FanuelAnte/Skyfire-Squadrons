extends Area2D

export (NodePath) var HealthComponent

func _ready():
	pass

func _physics_process(delta):
	pass

func _on_HurtboxComponent_area_entered(area):
	if area.is_in_group("bullet"):
		print(area.weapon_details.damage)
