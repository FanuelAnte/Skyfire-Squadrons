extends Resource

class_name plane_resource

export (int) var wingspan = 50
export (String, "Allied", "Axis") var alignment
export (String, "Great Britain", "United States", "Japan", "Germany", "Soviet Union") var country
export (int) var speed = 300
export (int) var bank_angle = 10
export (float) var max_bank_angle_factor = 1.5
export (float) var max_health = 100
