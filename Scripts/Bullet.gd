extends Area2D

export (Resource) var weapon_details
onready var sprite = $Sprite
var damage = 0

var rng = RandomNumberGenerator.new()

var who_shot_me

func _ready():
	sprite.frame = weapon_details.frame
	rng.randomize()
	assign_damage()

func _physics_process(delta):
	position += transform.x * weapon_details.speed * delta

func assign_damage():
	var is_critical = rng.randi_range(0, 5) > 3
	
	if is_critical:
		var val = rng.randi_range(0, 1)
		var curve_sample = weapon_details.criticality_curve.interpolate(val)
		var criticality = range_lerp(curve_sample, 0, 1, 1, weapon_details.max_damage)
		damage = criticality * weapon_details.base_damage
	else:
		damage = weapon_details.base_damage
	
func _on_Timer_timeout():
	self.queue_free()
