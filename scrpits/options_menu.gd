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
	var menu_buttons = get_node("../Menu Buttons")
	menu_buttons.ignore_input_for_one_frame = true
	get_tree().paused = false
	hide()
	ambient_loop.stop()
	menu_buttons.options_menu_open = false

	
func _on_volume_value_changed(value: float) -> void:
	var db = percent_to_db(value * 2)
	AudioServer.set_bus_volume_db(0, db)
