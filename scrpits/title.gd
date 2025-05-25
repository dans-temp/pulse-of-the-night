extends Control

@onready var start_button = $"Start Button"
@onready var options_button = $"Options Button"
@onready var options_menu_scene = $"../Options Menu"

var current_selected_button: Button = null
var mouse_pressed_button: Button = null
var mouse_hovering: bool = false
var options_menu_open = false
var ignore_input_for_one_frame = false

func _ready():
	# Godot 4 null-check for focus owner
	$AudioOptionSelect.process_mode = Node.PROCESS_MODE_ALWAYS
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
		$AudioOptionMove.play()

		if current_selected_button == null:
			_select_button(start_button)
		else:
			var next_button = options_button if current_selected_button == start_button else start_button
			_select_button(next_button)

	if Input.is_action_just_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			print("user accepted", focused.name)

			if focused.name == "Options Button":
				_open_options_menu()
				
#	omega jank i hate my life
	if ignore_input_for_one_frame:
		ignore_input_for_one_frame = false
		return

	if Input.is_action_just_pressed("ui_cancel") and not options_menu_open:
		$AudioOptionSelect.play()
		_open_options_menu()
			
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
				$AudioOptionSelect.play()
				if button.name == "Options Button":
					_open_options_menu()
			button.set_pressed(false)
			mouse_pressed_button = null
			
func _open_options_menu():
	if not options_menu_open:
		options_menu_scene.show_options_menu()
		options_menu_open = true
		get_tree().paused = true
