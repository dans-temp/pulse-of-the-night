extends Sprite2D

@export var bpm = 60
@export var scale_amount = 1.2
@export var pulse_duration = 0.1  # how fast it returns to normal

var pulse_timer = 0.0
var beat_interval : float
var pulsing = false
var pulsing_enabled := true

func _ready():
	beat_interval = 60.0 / bpm
	var player = get_node_or_null("../../../Player")
	if is_instance_valid(player):
		pulsing_enabled = false

func _process(delta):
	if material and material.shader:
		material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
	
	if pulsing_enabled:
		pulse_timer += delta
		if pulse_timer >= beat_interval:
			pulse()
			pulse_timer -= beat_interval

	# Smooth scale back to normal
	if pulsing:
		scale = scale.lerp(Vector2.ONE, delta / pulse_duration)

func pulse():
	scale = Vector2.ONE * scale_amount
	pulsing = true
