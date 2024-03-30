extends Resource

class_name plane_resource

export (String) var plane_name
export (String, "Allied", "Axis") var alignment
export (String, "Great Britain", "United States", "Japan", "Germany", "Soviet Union") var country

export (String, "Small Fighter", "Medium Fighter", "Bomber") var classification

export (int) var max_primary_ammo_count = 0
export (int) var max_secondary_ammo_count = 0
export (int) var max_tertiary_ammo_count = 0

export (int) var wingspan = 45

export (float) var g_force_increase_rate = 0.5
export (float) var g_force_decrease_rate = 5.0

export (int) var base_g_force_turn_factor = 1
export (int) var max_g_force_turn_factor = 5
export (int) var g_force_throttle_factor = 3

export (int) var coasting_duration_seconds = 60

export (int) var coasting_speed = 100
export (int) var cruise_speed = 200
export (int) var max_speed = 250

export (int) var bank_angle = 15
export (float) var max_bank_angle_factor = 1.5

export (float) var max_plane_health = 100.0
export (float) var max_fuel = 100.0

export (float) var fuel_burn_rate_standard = 0.1
export (float) var fuel_burn_rate_max = 0.2
