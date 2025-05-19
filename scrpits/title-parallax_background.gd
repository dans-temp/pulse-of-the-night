extends ParallaxBackground

@export var scroll_speed = Vector2(30, 0)  # pixels per second

func _process(delta):
	scroll_offset += scroll_speed * delta
