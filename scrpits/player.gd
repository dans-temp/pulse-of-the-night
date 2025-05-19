extends CharacterBody2D

@export var speed := 500.0
@export var gravity := 1000.0
@export var jump_velocity := -500.0
@export var attack_cooldown := 0 # seconds

var can_attack := true
var attack_timer := 0.0
var is_attacking := false

func _physics_process(delta):
	velocity.y += gravity * delta

	# Automatically move forward
	velocity.x = speed

	# Jumping is only allowed if not attacking
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# Attack input — only if on floor and not already attacking
	if Input.is_action_just_pressed("ui_right") and can_attack and is_on_floor() and not is_attacking:
		_attack()

	move_and_slide()

func _attack() -> void:
	is_attacking = true
	can_attack = false
	print("Player X: ", position.x, " Y: ", position.y)

	if $AnimationPlayer.has_animation("attack"):
		$AnimationPlayer.play("attack")

		# Wait before hitbox appears
		await get_tree().create_timer(0.2).timeout
		$AttackHitbox/CollisionShape2D2.disabled = false

		# Hitbox active duration
		await get_tree().create_timer(0.3).timeout
		$AttackHitbox/CollisionShape2D2.disabled = true

	# Wait for cooldown before allowing next attack
	await get_tree().create_timer(attack_cooldown).timeout

	is_attacking = false
	can_attack = true
	

func _on_animation_player_animation_finished(animation: String) -> void:
	if animation == "attack":
		is_attacking = false
		$AnimatedSprite2D.play("run")


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Baddies"):
		body.hit()
