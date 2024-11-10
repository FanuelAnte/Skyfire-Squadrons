extends Node2D

var parent_body
var current_health = 0

func _ready():
	parent_body = get_parent()
	current_health = parent_body.details.max_plane_health

func _process(delta):
	if current_health <= 0 and !parent_body.is_dead:
		parent_body.is_dead = true

func take_damage(damage_amount):
	if current_health > 0:
		current_health -= damage_amount
