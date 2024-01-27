extends Node2D

var plane_body
var plane_health = 0
var pilot_health = 0

func _ready():
	plane_body = get_parent()
	plane_health = plane_body.details.max_plane_health

#func _physics_process(delta):
#	if current_health <= 0:
#		self.queue_free()

func take_damage(damage_amount):
	if plane_health > 0:
		plane_health -= damage_amount
