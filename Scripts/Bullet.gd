extends Area2D

export (Resource) var weapon_details = preload("res://Scripts/Resources/WeaponResources/50 caliber Browning M2.tres")
onready var sprite = $Sprite

func _ready():
	sprite.frame = weapon_details.frame

func _physics_process(delta):
	position += transform.x * weapon_details.speed * delta

func _on_Timer_timeout():
	self.queue_free()
