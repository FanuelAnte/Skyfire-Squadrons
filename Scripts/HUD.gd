extends Control

onready var d_pad = $DPad
onready var action_buttons = $ActionButtons

onready var primary_ammo = $AmmoSection/PrimaryAmmo
onready var secondary_ammo = $AmmoSection/SecondaryAmmo

var plane_body

func _ready():
	plane_body = get_parent().get_parent()
	
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
