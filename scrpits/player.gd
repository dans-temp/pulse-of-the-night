extends CharacterBody2D

@onready var options_menu_scene = $"../CanvasLayer/Options Menu"

@export var speed := 500.0
@export var gravity := 2500.0
@export var jump_velocity := -842
@export var attack_cooldown := 0.50 # seconds

var can_attack := true
var is_attacking := false
var current_attack_id := 0
var attack_id := current_attack_id
var current_hang_id := 0
var peak_jump_height := 0
var is_hurt := false
var in_attack_animation := false
var is_invulnerable = false
var options_menu_open = false
var ignore_input_for_one_frame = false
var overlapping_enemies: Array = []
var attack_animation_index := 1
const MAX_ATTACK_ANIMATIONS := 3

var is_hanging := false

func _physics_process(delta):
	if not is_hanging:
		velocity.y += gravity * delta

	# Automatically move forward
	velocity.x = speed
	
	# Handle animations
	if is_on_floor() and not is_attacking and not is_hurt:
		if not $AnimatedSprite2D.animation.begins_with("attack") or \
		   $AnimatedSprite2D.frame == $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation) - 1:
			$AnimatedSprite2D.play("run")

	# Jump input
	if Input.is_action_just_pressed("ui_up") and can_attack and not is_attacking:
		print("Player X: ", position.x, " Y: ", position.y, 'AIR')
		if is_on_floor():
			_jump()
		elif can_attack:
			_air_attack()

	# Attack input
	if Input.is_action_just_pressed("ui_right") and can_attack and not is_attacking:
		print("Player X: ", position.x, " Y: ", position.y, 'GROUND')
		_attack('')
		
	# Open menu on escape
	if Input.is_action_just_pressed("ui_cancel") and not options_menu_open:
		if !ignore_input_for_one_frame:
			_open_options_menu()
		else:
			ignore_input_for_one_frame = false

	move_and_slide()
	
	

func _jump():
	velocity.y = jump_velocity  # Faster ascent
	peak_jump_height = position.y - 130
	$AnimationPlayer.stop()	
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

	await get_tree().create_timer(0.3).timeout
	if hang_id != current_hang_id:
		return

	is_hanging = false
	
func _jump_attack() -> void:
	$"../Dust/JumpDust".global_position.x = global_position.x
	$"../Dust/JumpDust".global_position.y = global_position.y
	$"../Dust/JumpDust".play()
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

	var this_attack_id
#	#some jank to stop air attaks that slam ground from hitting ariel baddies
	if not is_on_floor() and attack_type != 'air':
		velocity.y = 1500
		is_hanging = false
		current_hang_id += 1
		_start_attack_cooldown()
		this_attack_id = attack_id
		await get_tree().create_timer(0.05).timeout
	else:
		_start_attack_cooldown()
		this_attack_id = attack_id
	
	if $AnimatedSprite2D.animation.begins_with("attack"):
		$AnimatedSprite2D.stop()

#   looping attack animations
	var anim_name = "attack-%d" % attack_animation_index
	$AnimatedSprite2D.play(anim_name)

	attack_animation_index += 1
	if attack_animation_index > MAX_ATTACK_ANIMATIONS:
		attack_animation_index = 1

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
	if  $AnimatedSprite2D.animation.begins_with("attack") and attack_id == current_attack_id and is_on_floor():
		is_attacking = false
		$AnimatedSprite2D.play("run")


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		overlapping_enemies.append(body)
		# Delay to the next frame to gather all overlapping bodies
		call_deferred("_process_closest_enemy_hit")		

func _on_upper_cut_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		overlapping_enemies.append(body)
		# Delay to the next frame to gather all overlapping bodies
		call_deferred("_process_closest_enemy_hit")
		
		_start_hang_time()
		# Spawn spark effect at point of contact
		var spark_scene = preload("res://scenes/spark.tscn")
		var spark = spark_scene.instantiate()
		spark.global_position = body.global_position
		spark.global_position.x + 20
		get_tree().current_scene.add_child(spark)
		# Reset attack and cancel cooldown timer
		can_attack = true
		is_attacking = false
		current_attack_id += 1 
		
func _process_closest_enemy_hit():
	if overlapping_enemies.is_empty():
		return

	var closest_enemy: Node2D = null
	var min_distance := INF

	for enemy in overlapping_enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy

	if closest_enemy:
		closest_enemy.hit()

		# Spawn spark effect at point of contact
		var spark_scene = preload("res://scenes/spark.tscn")
		var spark = spark_scene.instantiate()
		spark.global_position = closest_enemy.global_position + Vector2(20, 0)
		get_tree().current_scene.add_child(spark)

		# Reset attack and cancel cooldown timer
		_end_attack_cooldown()
		current_attack_id += 1

	# Clear for next attack
	overlapping_enemies.clear()



func hurt():
	if is_invulnerable:
		return  # Ignore damage if invulnerable

	is_invulnerable = true
	can_attack = true
	is_attacking = false
	current_attack_id += 1

	is_hurt = true
	$AnimatedSprite2D.play("hurt")
	$AnimatedSprite2D.self_modulate = Color(10, 10, 10)
	$AudioStreamPlayer2D.play()

	# Start screen shake
	start_screen_shake()

	await get_tree().create_timer(0.10).timeout
	$AnimatedSprite2D.self_modulate = Color(1, 1, 1, 1)

	await get_tree().create_timer(0.20).timeout
	is_hurt = false

	await get_tree().create_timer(0.05).timeout  # Remaining invulnerability time (0.25s total)
	is_invulnerable = false


func start_screen_shake():
	var shake_amount = 4
	var shake_time = 0.1

	var cam = $Camera2D
	var original_offset = cam.offset

	# Do a quick shake using tween
	var tween = create_tween()
	tween.tween_property(cam, "offset", original_offset + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount)), shake_time / 2)
	tween.tween_property(cam, "offset", original_offset, shake_time / 2)
	
	
func _open_options_menu():
	if not options_menu_open:
		options_menu_scene.show_options_menu()
		$"../CanvasLayer/Options Menu/ChiptuneSelect".play()
		$"../CanvasLayer/Options Menu/MenuTheme".play()
		options_menu_open = true
		get_tree().paused = true
