extends Node2D

@onready var combo_numbers_label = $ComboNumbers

# Function to update the RichTextLabel with color transitions
func update_number_display(number: int):
	if number >= 100:
		# Rainbow effect for 100+
		var rainbow_text = create_rainbow_text(str(number))
		combo_numbers_label.text = rainbow_text
	else:
		# Color transition from white (0) to #f9ae2f (100)
		var color = interpolate_color(number)
		var color_hex = color.to_html(false)  # Get hex without alpha
		combo_numbers_label.text = "[color=#" + color_hex + "]" + str(number) + "[/color]"

# Interpolate between white and #f9ae2f based on the number (0-99)
func interpolate_color(number: int) -> Color:
	var white = Color(0.80, 0.80, 0.80)
	var target_color = Color("#f9ae2f")
	
	# Clamp number between 0 and 99, then normalize to 0.0-1.0
	var t = clamp(number, 0, 99) / 99.0
	
	# Interpolate between white and target color
	return white.lerp(target_color, t)

# Create rainbow text effect using built-in tag
func create_rainbow_text(text: String) -> String:
	return "[rainbow]" + text + "[/rainbow]"

# Example usage - call this whenever your number changes
func _on_number_changed(new_number: int):
	# Assuming you have a RichTextLabel node called NumberLabel
	update_number_display(new_number)
	
func shake_combo_text():
	var original_pos = combo_numbers_label.position

	var tween = get_tree().create_tween()
	tween.tween_property(combo_numbers_label, "position", original_pos + Vector2(6, 0), 0.05)
	tween.tween_property(combo_numbers_label, "position", original_pos - Vector2(6, 0), 0.05).set_delay(0.05)
	tween.tween_property(combo_numbers_label, "position", original_pos, 0.05).set_delay(0.10)
