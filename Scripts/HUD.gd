extends Control

onready var d_pad = $DPad
onready var action_buttons = $ActionButtons
onready var mini_map = $"%MiniMap"

onready var flight_time_label = $"%FlightTimeLabel"
onready var fuel_slider = $"%FuelSlider"
onready var g_force_label = $"%GForceLabel"
onready var g_force_slider = $"%GForceSlider"

onready var primary_name = $"%PrimaryName"
onready var secondary_name = $"%SecondaryName"

onready var primary_ammo = $"%PrimaryAmmo"
onready var secondary_ammo = $"%SecondaryAmmo"

onready var health_bar = $"%HealthBar"
onready var consciousness_bar = $"%ConsciousnessBar"

onready var framerate = $"%Framerate"

var plane_body
var artillery_component
var movement_component
var health_component

func _ready():
	plane_body = get_parent().get_parent()
	
	artillery_component = plane_body.get_node(plane_body.artillery_component)
	movement_component = plane_body.get_node(plane_body.movement_component)
	health_component = plane_body.get_node(plane_body.health_component)
	
	health_bar.max_value = plane_body.details.max_plane_health
	primary_name.text = artillery_component.primary_weapon.weapon_name
	secondary_name.text = artillery_component.secondary_weapon.weapon_name
	
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
	if plane_body.is_player and !plane_body.is_dead:
		primary_ammo.text = str(artillery_component.primary_ammo_count).pad_zeros(4)
		secondary_ammo.text = str(artillery_component.secondary_ammo_count).pad_zeros(4)
		
		health_bar.value = health_component.plane_health
		consciousness_bar.value = movement_component.consciousness
		
		fuel_slider.value = movement_component.fuel
		flight_time_label.text = str(movement_component.total_flight_time)
		
		g_force_slider.value = movement_component.g_force
		g_force_label.text = str(stepify((movement_component.g_force), 0.1)).pad_zeros(2).pad_decimals(1) + " G"
		
		framerate.text = str(Engine.get_frames_per_second())
		
		tween_hud_color(primary_ammo, artillery_component.primary_heat)
		tween_hud_color(secondary_ammo, artillery_component.secondary_heat)
	
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
