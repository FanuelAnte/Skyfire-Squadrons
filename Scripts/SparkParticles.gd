extends CPUParticles2D


func _ready():
	pass
	
func _process(delta):
	if !self.emitting:
		self.queue_free()
