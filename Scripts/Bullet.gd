extends Area2D

export (Resource) var weapon_details
onready var sprite = $Sprite

var who_shot_me

func _ready():
	sprite.frame = weapon_details.frame

func _physics_process(delta):
	position += transform.x * weapon_details.speed * delta

func _on_Timer_timeout():
	self.queue_free()
