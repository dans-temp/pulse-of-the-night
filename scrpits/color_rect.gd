extends ColorRect

func _ready():
	# Set initial screen size once (if not resizing)
	if material and material.shader:
		material.set_shader_parameter("screen_size", get_viewport_rect().size)

func _process(delta):
	if material and material.shader:
		material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
