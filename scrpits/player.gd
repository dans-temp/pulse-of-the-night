extends CharacterBody2D

@export var speed := 500.0
@export var gravity := 1000.0
@export var jump_velocity := -500.0
@export var attack_cooldown := 0.20 # seconds

var can_attack := true
var is_attacking := false
var current_attack_id := 0
var attack_id := current_attack_id

func _physics_process(delta):
	velocity.y += gravity * delta

	# Automatically move forward
	velocity.x = speed

	var just_jumped := false

	# Jumping is only allowed if not attacking
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity
		just_jumped = true
		$AnimationPlayer.play("jump")
		_jump_attack()

	# Attack input — only if on floor and not already attacking
	if Input.is_action_just_pressed("ui_right") and can_attack and is_on_floor() and not is_attacking:
		_attack()

	# Handle animations
	if is_on_floor() and not is_attacking:
		$AnimatedSprite2D.play("run")			

	move_and_slide()


func _attack() -> void:
	is_attacking = true
	can_attack = false
	current_attack_id += 1
	attack_id = current_attack_id
	print("Player X: ", position.x, " Y: ", position.y)

	if $AnimationPlayer.has_animation("attack"):
		$AnimationPlayer.play("attack")

		# Enable hitbox
		$AttackHitbox/CollisionShape2D2.disabled = false

		# Hitbox active duration
		await get_tree().create_timer(0.1).timeout
		$AttackHitbox/CollisionShape2D2.disabled = true

	# Wait for cooldown before allowing next attack — unless interrupted by a hit
	await get_tree().create_timer(attack_cooldown).timeout
	if attack_id == current_attack_id:
		can_attack = true
		is_attacking = false
		
		
func _jump_attack() -> void:
	$UpperCutHitBox/CollisionShape2D3.disabled = false
	await get_tree().create_timer(0.2).timeout
	$UpperCutHitBox/CollisionShape2D3.disabled = true

func _on_animation_player_animation_finished(animation: String) -> void:
	if animation == "attack":
		is_attacking = false
		$AnimatedSprite2D.play("run")


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		body.hit()
		
		# Spawn spark effect at point of contact
		var spark_scene = preload("res://scenes/spark.tscn")
		var spark = spark_scene.instantiate()
		spark.global_position = body.global_position
		get_tree().current_scene.add_child(spark)

		# Reset attack and cancel cooldown timer
		can_attack = true
		is_attacking = false
		current_attack_id += 1  # Cancels the current cooldown await if still running
		

func _on_upper_cut_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		body.hit()
		
		# Spawn spark effect at point of contact
		var spark_scene = preload("res://scenes/spark.tscn")
		var spark = spark_scene.instantiate()
		spark.global_position = body.global_position
		get_tree().current_scene.add_child(spark)



func hurt():
	# Flash white for one frame
	if attack_id == current_attack_id:
		can_attack = true
		is_attacking = false
		
	$AnimatedSprite2D.self_modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.self_modulate = Color(1, 1, 1, 1)
