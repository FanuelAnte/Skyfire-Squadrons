extends Area2D

var plane_body
var alignment

func _ready():
	plane_body = get_parent()
	alignment = plane_body.details.alignment

func _process(delta):
	pass
