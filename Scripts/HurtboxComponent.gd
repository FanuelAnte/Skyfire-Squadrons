extends Area2D

var spark_scene = preload("res://Scenes/SparkParticlesCPU.tscn")
onready var dodge_timer = $"%DodgeTimer"

export (NodePath) var HealthComponentPath
var health_component
var camera_component
var movement_component

var is_visible = false

var parent_body

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	parent_body = get_parent()
	health_component = get_node(HealthComponentPath)
	
	if parent_body.entity_type == "plane":
		camera_component = parent_body.get_node(parent_body.camera_component)
		movement_component = parent_body.get_node(parent_body.movement_component)

func damage_spark(hit_position, amount):
	var spark = spark_scene.instance()
	get_parent().add_child(spark)
	spark.amount = amount
	spark.emitting = true
	spark.global_position = hit_position

func _on_HurtboxComponent_area_entered(area):
	if area.is_in_group("bullet") and !parent_body.is_dead:
		if area.who_shot_me != parent_body:
			var damage = area.damage
			
			if area.is_critical:
				movement_component.is_being_shot = true
				if is_visible:
					damage_spark(area.global_position, 4)
					
			area.queue_free()
			health_component.take_damage(damage)
#			yield(get_tree().create_timer(stepify(rng.randf_range(0, 0.2), 0.1)), "timeout")
			movement_component.dodge_timer.start(stepify(rng.randf_range(0.5, parent_body.pilot.dodge_duration), 0.1))
			
			if parent_body.is_player:
				camera_component.camera_shake(0.5, 3)
				
				if OS.get_name() == "Android":
					Input.vibrate_handheld(40)
	
	
func _on_VisibilityNotifier2D_screen_entered():
	is_visible = true

func _on_VisibilityNotifier2D_screen_exited():
	is_visible = false
