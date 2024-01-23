extends Resource

class_name plane_resource

export (String) var plane_name
export (int) var wingspan = 50
export (String, "Allied", "Axis") var alignment
export (String, "Great Britain", "United States", "Japan", "Germany", "Soviet Union") var country

export (int) var coasting_duration_seconds = 300
export (int) var coasting_speed = 200
export (int) var cruise_speed = 300
export (int) var max_speed = 400

export (int) var bank_angle = 10
export (float) var max_bank_angle_factor = 1.5

export (float) var max_health = 100
export (float) var max_fuel = 60

export (float) var fuel_burn_rate_standard = 0.1
export (float) var fuel_burn_rate_max = 1
