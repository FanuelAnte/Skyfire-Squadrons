extends Control

onready var d_pad = $DPad
onready var action_buttons = $ActionButtons
onready var mini_map = $"%MiniMap"

onready var fuel_slider = $"%FuelSlider"
onready var g_force_slider = $"%GForceSlider"
onready var flight_time_label = $"%FlightTimeLabel"

onready var primary_name = $"%PrimaryName"
onready var secondary_name = $"%SecondaryName"

onready var primary_ammo = $"%PrimaryAmmo"
onready var secondary_ammo = $"%SecondaryAmmo"

onready var health_bar = $"%HealthBar"

var plane_body

func _ready():
	plane_body = get_parent().get_parent()
	
	health_bar.max_value = plane_body.details.max_health
	primary_name.text = plane_body.get_node(plane_body.artillery_component).primary_weapon.weapon_name
	secondary_name.text = plane_body.get_node(plane_body.artillery_component).secondary_weapon.weapon_name
	
	fuel_slider.max_value = plane_body.details.max_fuel
	
	if !plane_body.is_player:
		self.hide()
		
	if OS.get_name() == "Android":
		d_pad.show()
		action_buttons.show()
	else:
		d_pad.hide()
		action_buttons.hide()

func _physics_process(delta):
	if plane_body.is_player:
		primary_ammo.text = str(plane_body.get_node(plane_body.artillery_component).primary_ammo_count).pad_zeros(4)
		secondary_ammo.text = str(plane_body.get_node(plane_body.artillery_component).secondary_ammo_count).pad_zeros(4)
		
		health_bar.value = plane_body.get_node(plane_body.health_component).current_health
		
		fuel_slider.value = plane_body.get_node(plane_body.movement_component).fuel
		flight_time_label.text = str(plane_body.get_node(plane_body.movement_component).total_flight_time)
		
		tween_hud_color(primary_ammo, plane_body.get_node(plane_body.artillery_component).primary_heat)
		tween_hud_color(secondary_ammo, plane_body.get_node(plane_body.artillery_component).secondary_heat)
	
func tween_hud_color(node, value):
	var changed_value = range_lerp(value, 100, 0, 0, 1)
	node.modulate = Color(1, changed_value, changed_value)

func vibrate():
	Input.vibrate_handheld(40)

func _on_TurnLeftMax_pressed():
	vibrate()

func _on_TurnLeft_pressed():
	vibrate()

func _on_TurnRigh_pressed():
	vibrate()

func _on_TurnRighMax_pressed():
	vibrate()
