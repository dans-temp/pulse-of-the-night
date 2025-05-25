extends Control

@onready var start_button = $"Start Button"
@onready var options_button = $"Options Button"

var current_selected_button: Button = null
var mouse_pressed_button: Button = null
var mouse_hovering: bool = false

func _ready():
	# Godot 4 null-check for focus owner
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()

	# Ensure buttons receive mouse input
	start_button.mouse_filter = Control.MOUSE_FILTER_STOP
	options_button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Connect gui_input signals with parameters
	start_button.gui_input.connect(_on_button_gui_input.bind(start_button))
	options_button.gui_input.connect(_on_button_gui_input.bind(options_button))


func _process(delta):
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		$AudioStreamPlayer.play()

		# If no button is selected, start with the start_button
		if current_selected_button == null:
			_select_button(start_button)
		else:
			# Toggle to the other button
			var next_button = options_button if current_selected_button == start_button else start_button
			_select_button(next_button)

	if Input.is_action_just_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			print("user accepted", focused.name)
			
			
func _select_button(button: Button):
	current_selected_button = button
	button.grab_focus()
	

func _on_button_gui_input(event: InputEvent, button: Button):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Mouse down: remove focus so pressed style isn't blocked
			if button.has_focus():
				button.release_focus()
			button.set_pressed(true)
			mouse_pressed_button = button
		else:
			# Mouse up
			if mouse_pressed_button == button:
				print("user clicked", button.name)
			button.set_pressed(false)
			mouse_pressed_button = null
