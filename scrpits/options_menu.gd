extends Control

@onready var ambient_loop = $MenuTheme

func percent_to_db(percent: float) -> float:
	return linear_to_db(percent / 100.0)

func _ready():
	ambient_loop.stop()
	

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_visible():
		$ChiptuneSelect.play()
		_close_options_menu()
		
func show_options_menu():
	show()
	ambient_loop.play()

func _close_options_menu():
	
	var player = get_node_or_null("../../Player")
	if player:
		player.ignore_input_for_one_frame = true
		player.options_menu_open = false
	else:
		var menu_buttons = get_node_or_null("../Menu Buttons")
		if menu_buttons:
			menu_buttons.ignore_input_for_one_frame = true
			menu_buttons.options_menu_open = false

	get_tree().paused = false
	hide()
	ambient_loop.stop()

	
func _on_volume_value_changed(value: float) -> void:
	var db = percent_to_db(value * 2)
	AudioServer.set_bus_volume_db(0, db)
