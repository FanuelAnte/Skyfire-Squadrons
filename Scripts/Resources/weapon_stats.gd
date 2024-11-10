extends Resource

class_name weapon_resource

export (String) var weapon_name
export (int) var speed = 1500

export (float) var base_damage = 10.0
export (float) var max_damage = 10.0
export (int, 1, 5) var criticality_threshold
export (Curve) var criticality_curve

export (int) var frame = 0
#export (int) var max_ammo_count = 0
export (int) var delay_between_shots = 50
export (int) var effective_range = 128

export (float) var cooling_rate = 0.0
export (float) var heating_rate = 0.0
export (float) var heat_threshold = 0.0
export (float) var max_heat = 100.0
