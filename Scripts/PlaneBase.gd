extends KinematicBody2D

onready var camera = $Camera2D
onready var hud = $CanvasLayer/HUD

export (bool) var is_player = true
export (Resource) var details
export(NodePath) var target_node
export(NodePath) var artillery_component
