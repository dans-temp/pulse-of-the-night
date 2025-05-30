extends Camera2D

var shake_time := 0.0
var shake_strength := 5.0


@export var scroll_speed = Vector2(30, 0)  # pixels per second
@onready var tilemap = $"../TileMapLayer"
var scrolling := true


func stop_scroll():
	scrolling = false

func _process(delta):
	if scrolling:
		global_position += scroll_speed * delta
	if shake_time > 0:
		shake_time -= delta
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = Vector2.ZERO
		
	tilemap.global_position = global_position

func start_shake(duration: float, strength: float = 5.0):
	shake_time = duration
	shake_strength = strength
