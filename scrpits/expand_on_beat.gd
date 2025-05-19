extends Sprite2D


@export var bpm = 120
@export var scale_amount = 1.1
@export var pulse_duration = 0.1  # how fast it returns to normal

var pulse_timer = 0.0
var beat_interval : float
var pulsing = false

func _ready():
	beat_interval = 60.0 / bpm

func _process(delta):		
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
