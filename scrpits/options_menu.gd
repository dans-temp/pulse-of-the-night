extends Control

@onready var ambient_loop = $MenuTheme
@onready var volume_slider = $Panel2/MarginContainer/VBoxContainer/Volume

const SAVE_FILE_PATH = "user://volume_settings.save"

func percent_to_db(percent: float) -> float:
	if percent <= 0:
		return -80.0  # Essentially mute
	return linear_to_db(percent / 100.0)

func db_to_percent(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return db_to_linear(db) * 100.0

func _ready():
	ambient_loop.stop()
	load_volume_settings()

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_visible():
		$ChiptuneSelect.play()
		close_options_menu()

func show_options_menu():
	show()
	ambient_loop.play()

func close_options_menu():
	save_volume_settings()  # Save when closing
	
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
	var db = percent_to_db(value * 2)  # Assuming your slider goes 0-50, making it 0-100%
	AudioServer.set_bus_volume_db(0, db)
	# Optional: Save immediately on change instead of waiting for menu close
	# save_volume_settings()

func save_volume_settings():
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"master_volume": AudioServer.get_bus_volume_db(0)
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
	else:
		print("Failed to save volume settings")

func load_volume_settings():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		# Set default volume if no save file exists
		var default_db = percent_to_db(60.0)  # 60% default volume
		AudioServer.set_bus_volume_db(0, default_db)
		if volume_slider:
			volume_slider.value = 25.0  # 50% / 2 since you multiply by 2 in the change function
		return
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file:
		var json = JSON.new()
		var parse_result = json.parse(save_file.get_as_text())
		save_file.close()
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("master_volume"):
				var saved_db = save_data["master_volume"]
				AudioServer.set_bus_volume_db(0, saved_db)
				
				# Update slider to match saved volume
				if volume_slider:
					var saved_percent = db_to_percent(saved_db)
					volume_slider.value = saved_percent / 2.0  # Divide by 2 since you multiply by 2
		else:
			print("Failed to parse volume settings")
	else:
		print("Failed to load volume settings")
