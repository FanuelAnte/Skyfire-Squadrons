extends Area2D

export (Resource) var weapon_details
onready var sprite = $Sprite
var damage = 0
var is_critical = false
var who_shot_me

var rng = RandomNumberGenerator.new()

func _ready():
	sprite.frame = weapon_details.frame
	rng.randomize()
	assign_damage()

func _process(delta):
	position += transform.x * weapon_details.speed * delta

func assign_damage():
	is_critical = rng.randi_range(0, 5) > weapon_details.criticality_threshold
	
	if is_critical:
		var val = rng.randf_range(0, 1)
		var curve_sample = weapon_details.criticality_curve.interpolate(val)
		var criticality = stepify(range_lerp(curve_sample, 0, 1, 1, weapon_details.max_damage), 0.01)
		damage = criticality * weapon_details.base_damage
	else:
		damage = weapon_details.base_damage
	
func _on_Timer_timeout():
	self.queue_free()
