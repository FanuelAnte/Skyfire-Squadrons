extends KinematicBody2D

onready var camera = $Camera2D

export (bool) var is_player = true
export (Resource) var details
export(NodePath) var target_node
