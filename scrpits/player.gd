extends CharacterBody2D

@export var speed := 500.0
@export var gravity := 2500.0
@export var jump_velocity := -550.0
@export var attack_cooldown := 0.50 # seconds

var can_attack := true
var is_attacking := false
var current_attack_id := 0
var attack_id := current_attack_id
var current_hang_id := 0
var peak_jump_height := 0

var is_hanging := false

func _physics_process(delta):
	if not is_hanging:
		velocity.y += gravity * delta

	# Automatically move forward
	velocity.x = speed
	
	# Handle animations
	if is_on_floor() and not is_attacking:
		$AnimatedSprite2D.play("run")		

	# Jump input
	if Input.is_action_just_pressed("ui_up") and can_attack and not is_attacking:
		if is_on_floor():
			_jump()
		elif can_attack:
			_air_attack()

	# Attack input
	if Input.is_action_just_pressed("ui_right") and can_attack and not is_attacking:
		_attack('')


	move_and_slide()

func _jump():
	velocity.y = jump_velocity * 1.5  # Faster ascent
	peak_jump_height = position.y - 120
	$AnimationPlayer.play("jump")
	_jump_attack()


func _start_hang_time() -> void:
	current_hang_id += 1
	var hang_id = current_hang_id

	await get_tree().create_timer(0.10).timeout
	if hang_id != current_hang_id:
		return

	velocity.y = 0
	position.y = peak_jump_height
	is_hanging = true

	await get_tree().create_timer(0.5).timeout
	if hang_id != current_hang_id:
		return

	is_hanging = false
	
func _jump_attack() -> void:
	_start_attack_cooldown()
	$UpperCutHitBox/CollisionShape2D3.disabled = false
	await get_tree().create_timer(0.2).timeout
	$UpperCutHitBox/CollisionShape2D3.disabled = true
	await get_tree().create_timer(attack_cooldown).timeout
	_end_attack_cooldown()
	
func _air_attack() -> void:
	_start_hang_time()
	_attack('air')

func _attack(attack_type) -> void:
	print("Player X: ", position.x, " Y: ", position.y)

	if not is_on_floor() and attack_type != 'air':
		velocity.y = 1500
		is_hanging = false
		current_hang_id += 1

	_start_attack_cooldown()
	var this_attack_id = attack_id  # Capture current attack ID

	$AnimationPlayer.play("attack")

	# Enable hitbox
	$AttackHitbox/CollisionShape2D2.disabled = false
	await get_tree().create_timer(0.1).timeout
	$AttackHitbox/CollisionShape2D2.disabled = true

	# Cooldown duration
	await get_tree().create_timer(attack_cooldown).timeout
	if this_attack_id == current_attack_id:
		_end_attack_cooldown()


func _start_attack_cooldown() -> void:
	is_attacking = true
	can_attack = false
	current_attack_id += 1
	attack_id = current_attack_id
	

func _end_attack_cooldown() -> void:
	can_attack = true
	is_attacking = false
		

func _on_animation_player_animation_finished(animation: String) -> void:
	if animation == "attack" and attack_id == current_attack_id:
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
		current_attack_id += 1 
		

func _on_upper_cut_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		body.hit()
		
		_start_hang_time()
		# Spawn spark effect at point of contact
		var spark_scene = preload("res://scenes/spark.tscn")
		var spark = spark_scene.instantiate()
		spark.global_position = body.global_position
		get_tree().current_scene.add_child(spark)
		# Reset attack and cancel cooldown timer
		can_attack = true
		is_attacking = false
		current_attack_id += 1 



func hurt():
	# Flash white for one frame
	can_attack = true
	is_attacking = false
	current_attack_id += 1
		
	$AnimatedSprite2D.self_modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.self_modulate = Color(1, 1, 1, 1)
