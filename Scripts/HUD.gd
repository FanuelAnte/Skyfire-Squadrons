extends Control

onready var d_pad = $DPad
onready var action_buttons = $ActionButtons
onready var mini_map = $"%MiniMap"

onready var primary_ammo = $"%PrimaryAmmo"
onready var secondary_ammo = $"%SecondaryAmmo"
onready var health_bar = $"%HealthBar"

var plane_body

func _ready():
	plane_body = get_parent().get_parent()
	health_bar.max_value = plane_body.details.max_health
	
	if !plane_body.is_player:
		self.hide()
		
	if OS.get_name() == "Android":
		d_pad.show()
		action_buttons.show()
	else:
		d_pad.hide()
		action_buttons.hide()

func _physics_process(delta):
	primary_ammo.text = str(plane_body.get_node(plane_body.artillery_component).primary_ammo_count)
	health_bar.value = plane_body.get_node(plane_body.health_component).current_health
	tween_hud_color(primary_ammo, plane_body.get_node(plane_body.artillery_component).primary_heat)
	
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
