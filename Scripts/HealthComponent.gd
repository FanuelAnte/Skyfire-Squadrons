extends Node2D

var plane_body
var current_health

func _ready():
	plane_body = get_parent()
	current_health = plane_body.details.max_health

func _physics_process(delta):
	pass

func take_damage(damage_amount):
	if current_health > 0:
		current_health -= damage_amount
