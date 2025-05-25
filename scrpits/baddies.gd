extends RigidBody2D

var is_dead = false

func _ready():
	gravity_scale = 0
	linear_velocity  = Vector2(-150, 0)
	

func hit():
	# Disable collisions
	if is_dead:
		return
		
	is_dead = true
	$Hitbox/CollisionShape2D.disabled = true

	# Launch upward
	linear_velocity = Vector2(-300, -500)
	gravity_scale = 1

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
	
