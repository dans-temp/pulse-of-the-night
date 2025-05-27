extends CharacterBody2D

@export var speed := -60.0
var is_dead = false
var gravity := 1200.0  # Adjust as needed

func _ready():
	# Start moving left
	velocity = Vector2(speed, 0)

func _physics_process(delta):
	if not is_dead:
		velocity.x = speed
		velocity.y = 0
	else:
		velocity.y += gravity * delta  # Apply gravity when dead

	move_and_slide()

func hit():
	if is_dead:
		return

	is_dead = true
	$Hitbox/CollisionShape2D.disabled = true
	var moon = get_node_or_null("../../ParallaxBackground/Moon")
	if moon:
		moon.get_node("ColorRect").pulse()
		moon.get_node("Sprite2D").pulse()
	# Launch upward
	velocity = Vector2(-300, -500)

	# Play sound and animation
	$HitSound.play()
	$AnimationPlayer.play("death")

	# Flash white for one frame
	$AnimatedSprite2D.self_modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.self_modulate = Color(1, 1, 1, 1)

	# Wait for animation to finish, then remove
	await $AnimationPlayer.animation_finished
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("PlayerAttackHitbox"):
		print("Ignore attack hitbox")
		return
	if body.is_in_group("Player"):
		$Hitbox/CollisionShape2D.disabled = true
		body.hurt()
