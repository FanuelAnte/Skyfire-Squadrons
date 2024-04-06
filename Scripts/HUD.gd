extends Control

onready var d_pad = $"%DPad"
onready var action_buttons = $"%ActionButtons"
onready var zoom_buttons = $"%ZoomButtons"

onready var mini_map = $"%MiniMap"

onready var flight_time_label = $"%FlightTimeLabel"
onready var fuel_slider = $"%FuelSlider"
onready var g_force_label = $"%GForceLabel"
onready var g_force_slider = $"%GForceSlider"

onready var primary_name = $"%PrimaryName"
onready var secondary_name = $"%SecondaryName"
onready var tertiary_name = $"%TertiaryName"

onready var primary_ammo = $"%PrimaryAmmo"
onready var secondary_ammo = $"%SecondaryAmmo"
onready var tertiary_ammo = $"%TertiaryAmmo"

onready var health_bar = $"%HealthBar"
onready var consciousness_bar = $"%ConsciousnessBar"

onready var pass_out = $"%PassOut"

onready var framerate = $"%Framerate"

onready var fire_primary = $"%FirePrimary"
onready var fire_secondary = $"%FireSecondary"
onready var fire_tertiary = $"%FireTertiary"

onready var drag_s = $"%DragS"
onready var drag_c = $"%DragC"
onready var drag_controls = $"%DragControls"

onready var throttle_button = $"%ThrottleButton"

onready var drag_amount_label = $"%DragAmountLabel"

onready var coordinates_label = $"%CoordinatesLabel"

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
	tertiary_name.text = artillery_component.tertiary_weapon.weapon_name
	
	fuel_slider.max_value = plane_body.details.max_fuel
	
	if !plane_body.is_player:
		self.hide()
		
	if OS.get_name() == "Android":
#		make it an option in the settings to choose between d-pad and drag controls.
#		d_pad.show()
		throttle_button.show()
		action_buttons.show()
		zoom_buttons.show()
		
		if plane_body.details.classification == "Small Fighter":
			fire_primary.show()
			fire_secondary.show()
			fire_tertiary.show()
		
		elif plane_body.details.classification == "Medium Fighter":
			fire_primary.show()
			fire_secondary.show()
			fire_tertiary.show()
		
		elif plane_body.details.classification == "Bomber":
			fire_primary.hide()
			fire_secondary.hide()
			fire_tertiary.show()
		
	else:
		d_pad.hide()
		throttle_button.hide()
		action_buttons.hide()
		zoom_buttons.hide()

func _process(delta):
	if plane_body.is_player and !plane_body.is_dead:
		primary_ammo.text = str(artillery_component.primary_ammo_count).pad_zeros(4)
		secondary_ammo.text = str(artillery_component.secondary_ammo_count).pad_zeros(4)
		tertiary_ammo.text = str(artillery_component.tertiary_ammo_count).pad_zeros(4)
		
		health_bar.value = health_component.plane_health
		consciousness_bar.value = movement_component.consciousness
		
		fuel_slider.value = movement_component.fuel
		flight_time_label.text = str(movement_component.total_flight_time)
		
		if movement_component.fuel_critical:
			flight_time_label.self_modulate =  Color(1, 0, 0)
		
		g_force_slider.value = movement_component.g_force
		g_force_label.text = str(stepify((movement_component.g_force), 0.1)).pad_zeros(2).pad_decimals(1) + " G"
		
		coordinates_label.text = "X:" + str(stepify(plane_body.global_position.x, 1)).pad_zeros(4) + " " + "Y:" + str(stepify(plane_body.global_position.y, 1)).pad_zeros(4)
		
		framerate.text = str(Engine.get_frames_per_second())
		drag_amount_label.text = str(int(movement_component.drag_distance))
		
		tween_hud_color(primary_ammo, artillery_component.primary_heat, artillery_component.primary_weapon.max_heat)
		tween_hud_color(secondary_ammo, artillery_component.secondary_heat, artillery_component.secondary_weapon.max_heat)
		
		tween_pass_out_filter(movement_component.consciousness)
		
		if OS.get_name() == "Android":
			if movement_component.is_dragging and movement_component.drag_start_position != null:
				drag_controls.show()
				drag_s.global_position = movement_component.drag_start_position - Vector2 (0, 64)
				drag_c.global_position.x = drag_s.global_position.x + movement_component.drag_distance
			else:
				drag_controls.hide()
	
func tween_hud_color(node, value, max_heat):
	var changed_value = range_lerp(value, max_heat, 0, 0, 1)
	node.self_modulate = Color(1, changed_value, changed_value)

func tween_pass_out_filter(value):
	var changed_value_scale = range_lerp(value, 10, 0, 1, 0.5)
	var changed_value_softness = range_lerp(value, 10, 0, 1.5, 1)
	pass_out.material.set_shader_param("SCALE", changed_value_scale)
	pass_out.material.set_shader_param("SOFTNESS", changed_value_softness)
	
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
