extends KinematicBody2D

onready var hud = $CanvasLayer/HUD

export (bool) var is_player = true
export (Resource) var details
export (Resource) var pilot
export(NodePath) var target_node
export(NodePath) var artillery_component
export(NodePath) var health_component
export(NodePath) var movement_component
export(NodePath) var camera_component

var targeted = false
var is_dead = false

func _process(delta):
	if is_dead:
		$Explosion.show()
		$AnimationPlayer.play("explosion")
