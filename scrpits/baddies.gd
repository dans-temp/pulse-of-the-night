extends CharacterBody2D

@export var speed := -60.0
var is_dead := false
var gravity := 1200.0  # Adjust as needed\
var already_hit_player := false
var already_broke_combo := false
var player

func _ready():
	# Start moving left
	velocity = Vector2(speed, 0)
	if has_node("../../Player"):
		player = get_node("../../Player")
	else:
		player = null

func _physics_process(delta):
	if not is_dead:
		velocity.x = speed
		velocity.y = 0

		#handle missed enemies
		if not already_hit_player and not already_broke_combo and player and global_position.x < player.get_node("ComboBreakLine").global_position.x:
			already_broke_combo = true
			player.break_combo()
		
	else:
		velocity.y += gravity * delta  # Apply gravity when dead

	move_and_slide()
	
#baddie got hit
func hit():
	if is_dead or already_hit_player:
		return

	is_dead = true
	var spark_scene = preload("res://scenes/spark.tscn")
	var spark = spark_scene.instantiate()
	spark.global_position = global_position + Vector2(20, 0)
	get_tree().current_scene.add_child(spark)
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
	if is_dead or body.is_in_group("PlayerAttackHitbox"):
		return
	if body.is_in_group("Player"):
		already_hit_player = true
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		body.hurt()
