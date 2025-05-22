extends Node2D

func _ready():
	$AnimatedSprite2D.play("spark")
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	queue_free()
