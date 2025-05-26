extends Control

@onready var start_button = $"Start Button"
@onready var options_button = $"Options Button"
@onready var quit_button = $"Quit Button"
@onready var options_menu_scene = $"../Options Menu"
@onready var shader = load("res://shaders/sprite_silhouette.gdshader")
@onready var baddies = $"../../Baddies"

var current_selected_button: Button = null
var mouse_pressed_button: Button = null
var mouse_hovering: bool = false
var options_menu_open = false
var ignore_input_for_one_frame = false
var game_started = false
var baddie_spawn_x: Array[float] = []

var button_order: Array[Button] = []  # Array of buttons for nav

func _ready():

	$AudioOptionSelect.process_mode = Node.PROCESS_MODE_ALWAYS

	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()

	# Set mouse filter
	for button in [start_button, options_button, quit_button]:
		button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Add buttons to nav array in desired order
	button_order = [start_button, options_button, quit_button]

	# Connect gui_input signals
	for button in button_order:
		button.gui_input.connect(_on_button_gui_input.bind(button))
		
		
	# Apply silhouette shader to all baddies
	for baddie in baddies.get_children():
		var sprite = baddie.get_node_or_null("AnimatedSprite2D")
		if sprite == null:
			# Try searching recursively if it's nested
			sprite = baddie.get_node_or_null("Sprite") or baddie.find_child("AnimatedSprite2D", true, false)
		
		if sprite and sprite is CanvasItem:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = shader
			sprite.material = shader_material
			
		# Freeze baddie by setting linear_velocity to zero
		if baddie is CharacterBody2D:
			baddie_spawn_x.append(baddie.position.x)
			baddie.hide()


func _process(delta):
		# Open menu on escape
	if Input.is_action_just_pressed("ui_cancel") and not options_menu_open:
		if !ignore_input_for_one_frame:
			$AudioOptionSelect.play()
			_open_options_menu()
		else:
			ignore_input_for_one_frame = false
		
	if game_started:
		return

	# Handle left/right navigation
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		$AudioOptionMove.play()

		if current_selected_button == null:
			_select_button(start_button)
		else:
			var index = button_order.find(current_selected_button)
			if index != -1:
				var direction = -1 if Input.is_action_just_pressed("ui_left") else 1
				var next_index = (index + direction + button_order.size()) % button_order.size()
				_select_button(button_order[next_index])

	# Handle confirm
	if Input.is_action_just_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			match focused.name:
				"Start Button":
					_start_game()
				"Options Button":
					_open_options_menu()
				"Quit Button":
					_quit_game()


func _select_button(button: Button):
	current_selected_button = button
	button.grab_focus()

func _on_button_gui_input(event: InputEvent, button: Button):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			if button.has_focus():
				button.release_focus()
			button.set_pressed(true)
			mouse_pressed_button = button
		else:
			if mouse_pressed_button == button:
				match button.name:
					"Start Button":
						_start_game()
					"Options Button":
						_open_options_menu()
					"Quit Button":
						_quit_game()
			button.set_pressed(false)
			mouse_pressed_button = null

func _open_options_menu():
	if not options_menu_open:
		$AudioOptionSelect.play()
		options_menu_scene.show_options_menu()
		options_menu_open = true
		get_tree().paused = true

func _start_game():
	if game_started:
		return
	game_started = true
	$"../../Songs/TitleTheme".stop()
	$AudioOptionSelect.play()
	await get_tree().create_timer(0.20).timeout
	$"../../Songs/TutorialTheme".play()

	# Hide one background layer and the UI
	$"../../ParallaxBackground/Title".hide()
	hide()
	

	# Stop scrolling
	$"../../TitleCamera".stop_scroll()

	# Flash the screen white
	var flash_rect = $"../FlashRect"
	flash_rect.show()
	$"../FlashRect/AnimationPlayer".play("flash")

	# Start screen shake
	$"../../TitleCamera".start_shake(1.0, 2.0)
	$"../../ParallaxBackground/Player/AnimatedSprite2D".hide()
	$"../../ParallaxBackground/Doesnt move until game starts/BackgroundWalkAnimation".show()
	$"../../ParallaxBackground/Doesnt move until game starts/BackgroundWalkAnimation".play()
#	# re adjust parallax layers
	$"../../ParallaxBackground/ParallaxLayer2".motion_scale = Vector2(0.1, 1)
	$"../../ParallaxBackground/Doesnt move until game starts".motion_scale = Vector2(1, 1)
	$"../../ParallaxBackground/ParallaxLayer3".motion_scale = Vector2(0.2, 1)
	$"../../ParallaxBackground/ParallaxLayer5".motion_scale = Vector2(0.4, 1)
	$"../../ParallaxBackground/ParallaxLayer6".motion_scale = Vector2(0.6, 1)
	$"../../CutsceneAnimation".play("start_cutscene")
	
	await get_tree().create_timer(5.0).timeout

	# Load and instance the Player scene
	var player_scene = preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()

	player.global_position = Vector2(2600.0, 480)  # spawn position

	# Add the player to the scene tree
	get_tree().current_scene.add_child(player)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Apply the shader to the AnimatedSprite2D inside the player instance
	var sprite = player.get_node("AnimatedSprite2D")
	sprite.material = shader_material

	# Make the player's camera active
	var player_camera = player.get_node("Camera2D")
	player_camera.make_current()
	
		# Restore positions to baddies
	for i in baddies.get_child_count():
		var baddie = baddies.get_child(i)
		if baddie is CharacterBody2D:
			baddie.position.x = baddie_spawn_x[i]
			print(baddie.position.x)
			baddie.show()

	
func _quit_game():
	get_tree().quit()
