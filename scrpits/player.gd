extends CharacterBody2D

@onready var options_menu_scene = $"../CanvasLayer/Options Menu"
@onready var ground_check := $GroundCheck
@onready var sprite := $AnimatedSprite2D
@onready var combo_display_number := $"../CanvasLayer/ComboDisplay/ComboNumbers"
@onready var health_bar_display := $"../CanvasLayer/HealthDisplay"

@export var speed := 500.0
@export var gravity := 2500.0
@export var jump_velocity := -842
@export var attack_cooldown := 0.50 # seconds
@export var max_hp := 4
@export var current_hp := max_hp

var can_attack := true
var is_attacking := false
var current_attack_id := 0
var attack_id := current_attack_id
var current_hang_id := 0
var peak_jump_height := 0
var is_hurt := false
var hurt_last_frame := false
var in_attack_animation := false
var is_invulnerable = false
var options_menu_open = false
var has_processed_hit: bool = false
var ignore_input_for_one_frame = false
var overlapping_enemies: Array = []
var attack_animation_index := 1
const MAX_ATTACK_ANIMATIONS := 3
var is_hanging := false
var combo_count := 0


func _physics_process(delta):
	if not is_hanging:
		velocity.y += gravity * delta

	# Automatically move forward
	velocity.x = speed
	
	# Handle animations
	if is_on_floor() and not is_attacking and not is_hurt:
		if not sprite.animation.begins_with("attack") or \
		   sprite.frame == sprite.sprite_frames.get_frame_count(sprite.animation) - 1:
			sprite.play("run")

	# Attack input
	if Input.is_action_just_pressed("ui_right") and can_attack and not is_attacking:
		print("Player X: ", position.x, " Y: ", position.y, 'GROUND')
		_attack()
		
	# Jump input
	elif Input.is_action_just_pressed("ui_up") and can_attack and not is_attacking:
		#print("Player X: ", position.x, " Y: ", position.y, 'AIR')
		if is_on_floor():
			_jump()
		else:
			_air_attack()
		
	# Open menu on escape
	elif Input.is_action_just_pressed("ui_cancel") and not options_menu_open:
		if !ignore_input_for_one_frame:
			_open_options_menu()
		else:
			ignore_input_for_one_frame = false
			
	if hurt_last_frame == true:
		hurt_last_frame = false

	move_and_slide()
	

func _jump():
	velocity.y = jump_velocity
	peak_jump_height = position.y - 130
	sprite.stop()	
	sprite.play("jump")
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

	await get_tree().create_timer(0.25).timeout
	if hang_id != current_hang_id:
		return

	is_hanging = false
	
func _jump_attack() -> void:
	has_processed_hit = false 
	$"../Dust/JumpDust".global_position = global_position
	$"../Dust/JumpDust".play()
	var this_attack_id = _start_attack_cooldown()
	
	$UpperCutHitBox/CollisionShape2D3.disabled = false
	await get_tree().create_timer(0.2).timeout
	$UpperCutHitBox/CollisionShape2D3.disabled = true
	await get_tree().create_timer(attack_cooldown).timeout
	
	#	add block and side hit box here too i think
	if this_attack_id == current_attack_id and $AttackHitbox/CollisionShape2D2.disabled and $UpperCutHitBox/CollisionShape2D3.disabled:
		_end_attack_cooldown()
	
func _air_attack() -> void:
	_start_hang_time()
	_attack('air')

func _attack(attack_type = null) -> void:

	var this_attack_id
	has_processed_hit = false
	this_attack_id = _start_attack_cooldown()
#	#some jank to stop air attaks that slam ground from hitting ariel baddies
	if not is_on_floor() and attack_type != 'air':
		velocity.y = 1500
		is_hanging = false
		current_hang_id += 1
		await get_tree().create_timer(0.05).timeout
	
	if sprite.animation.begins_with("attack"):
		sprite.stop()

#   looping attack animations
	var anim_name = "attack-%d" % attack_animation_index
	sprite.play(anim_name)

	attack_animation_index += 1
	if attack_animation_index > MAX_ATTACK_ANIMATIONS:
		attack_animation_index = 1

	# Enable hitbox
	$AttackHitbox/CollisionShape2D2.disabled = false
	await get_tree().create_timer(0.1).timeout
	$AttackHitbox/CollisionShape2D2.disabled = true

	# Cooldown duration
	await get_tree().create_timer(attack_cooldown).timeout
#	add block and side hit box here too i think
	if this_attack_id == current_attack_id and $AttackHitbox/CollisionShape2D2.disabled and $UpperCutHitBox/CollisionShape2D3.disabled:
		_end_attack_cooldown()


func _start_attack_cooldown() -> int:
	is_attacking = true
	can_attack = false
	current_attack_id += 1
	attack_id = current_attack_id
	return attack_id
	

func _end_attack_cooldown() -> void:	
	can_attack = true
	is_attacking = false
		
		
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		overlapping_enemies.append(body)
			
		# Delay to the next frame to gather all overlapping bodies
		if not has_processed_hit:
			call_deferred("_process_closest_enemy_hit")

func _on_upper_cut_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies") and not is_on_floor():
		_start_hang_time()
		overlapping_enemies.append(body)
			
		# Delay to the next frame to gather all overlapping bodies
		if not has_processed_hit:
			call_deferred("_process_closest_enemy_hit")
		
		
func _process_closest_enemy_hit():
	if has_processed_hit or overlapping_enemies.is_empty() or hurt_last_frame:
		return

	has_processed_hit = true

	var closest_enemy: Node2D = null
	var min_distance := INF

	for enemy in overlapping_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.is_dead:
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy

	if closest_enemy:
		closest_enemy.hit()
		combo_count += 1
		combo_display_number.bbcode_text  = "[center]%d[/center]" % combo_count

		_end_attack_cooldown()

	# Clear for next attack
	overlapping_enemies.clear()

func hurt():
	if is_invulnerable:
		return
		
	current_hp -= 1
	health_bar_display.update_hearts()
	
#	pauses and ends the scene
	if current_hp == 0:
		_game_over()
	
	is_invulnerable = true
	can_attack = true
	is_attacking = false
	current_attack_id += 1

	is_hurt = true
	hurt_last_frame = true
	sprite.play("hurt")
	sprite.self_modulate = Color(10, 10, 10)
	$GotHitSound.play()

	# Start screen shake
	start_screen_shake()
	
	break_combo()
	await get_tree().create_timer(0.10).timeout
	sprite.self_modulate = Color(1, 1, 1, 1)

	await get_tree().create_timer(0.20).timeout
	is_hurt = false

	await get_tree().create_timer(0.05).timeout  # Remaining invulnerability time (0.25s total)
	is_invulnerable = false


func start_screen_shake():
	var shake_amount = 8
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
		
		
func _game_over():
	print('GG')
	
	

#baddies call this when they break the combo
func break_combo():
	if combo_count > 0:
		combo_count = 0
		combo_display_number.bbcode_text  = "[center]%d[/center]" % combo_count
		shake_combo_text()


func shake_combo_text():
	var label = combo_display_number
	var original_pos = label.position

	var tween = get_tree().create_tween()
	tween.tween_property(label, "position", original_pos + Vector2(6, 0), 0.05)
	tween.tween_property(label, "position", original_pos - Vector2(6, 0), 0.05).set_delay(0.05)
	tween.tween_property(label, "position", original_pos, 0.05).set_delay(0.10)
