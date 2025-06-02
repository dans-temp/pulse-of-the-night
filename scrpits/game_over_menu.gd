extends Control

@onready var retry_button := $"FinalGameOver/Menu Buttons/RetryButton"
@onready var select_level_button := $"FinalGameOver/Menu Buttons/LevelSelectButton"
@onready var title_screen_button := $"FinalGameOver/Menu Buttons/TitleScreenButton"
@onready var title_screen_scene := "res://scenes/title.tscn"

var current_selected_button: Button = null
var mouse_pressed_button: Button = null
var mouse_hovering: bool = false
var button_order: Array[Button] = []  # Array of buttons for nav

func _ready():

	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()

	# Set mouse filter
	for button in [retry_button, select_level_button, title_screen_button]:
		button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Add buttons to nav array in desired order
	button_order = [retry_button, select_level_button, title_screen_button]

	# Connect gui_input signals
	for button in button_order:
		button.gui_input.connect(_on_button_gui_input.bind(button))
	
	_select_button(retry_button)
	

func _process(delta):
		
	if not $FinalGameOver.visible:
		return
	# Handle left/right navigation
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		$"FinalGameOver/Menu Buttons/AudioOptionMove".play()

		if current_selected_button == null:
			_select_button(retry_button)
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
			$"FinalGameOver/Menu Buttons/AudioOptionSelect".play()
			await get_tree().create_timer(0.50).timeout
			match focused.name:
				"RetryButton":
					get_tree().paused = false
					get_tree().reload_current_scene()
				"LevelSelectButton":
					print('level select pressed')
				"TitleScreenButton":
					get_tree().paused = false
					get_tree().change_scene_to_file(title_screen_scene)	


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
				$"FinalGameOver/Menu Buttons/AudioOptionSelect".play()
				await get_tree().create_timer(0.50).timeout
				match button.name:
					"RetryButton":
						get_tree().paused = false
						get_tree().reload_current_scene()
					"LevelSelectButton":
						print('level select pressed')
					"TitleScreenButton":
						get_tree().paused = false
						get_tree().change_scene_to_file(title_screen_scene)
			button.set_pressed(false)
			mouse_pressed_button = null
			
			
func game_over_animation(player_position, camera):
	$FinalGameOver/GameOverSound.play()
	var cutscene_bg = $GameOverCutscene/CutsceneBG
	var dead_player = $GameOverCutscene/DeadPlayer
	cutscene_bg.modulate.a = 0.0
	
	# Create a tween to fade in over 0.4 seconds
	var tween = create_tween()
	tween.tween_property(cutscene_bg, "modulate:a", 1.0, 0.8)
	await get_tree().create_timer(1).timeout

	# Convert player world position to screen space
	var canvas_transform = get_viewport().get_canvas_transform()
	var screen_position = (canvas_transform * player_position) + Vector2(70, -45)
	dead_player.position = screen_position
	
	dead_player.modulate.a = 0.2
	var tween0 = create_tween()
	tween0.tween_property(dead_player, "modulate:a", 1.0, 0.5)
	dead_player.visible = true
	dead_player.play("death")
	await get_tree().create_timer(0.20).timeout
	$GameOverCutscene/DyingGrunt.play()
	await get_tree().create_timer(0.20).timeout
	$FinalGameOver/GameOverTheme.play()
	var tween2 = create_tween()
	tween2.tween_property(dead_player, "modulate", Color.BLACK,3.0)
	$FinalGameOver/RichTextLabel.modulate = Color.BLACK
	$FinalGameOver.modulate = Color(0, 0, 0, 0)
	$FinalGameOver.visible = true
	_select_button(retry_button)
	var rich_text = $FinalGameOver/RichTextLabel
	var tween3 = create_tween()
	tween3.parallel().tween_property(rich_text, "modulate:a", 1.0, 1.0)
	tween3.parallel().tween_property(rich_text, "modulate", Color.WHITE, 1.0)
	var tween4 = create_tween()
	tween4.tween_property($FinalGameOver, "modulate", Color.WHITE, 1.0)
	
