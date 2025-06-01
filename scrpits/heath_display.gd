extends Node2D

const FULL_HEART_TEXTURE := preload("res://assets/ui_elements/heart-purp.png")
const BROKEN_HEART_ANIMATION := preload("res://scenes/empty_heart.tscn")
const EMPTY_HEART_TEXTURE := preload("res://assets/ui_elements/heart-empty.png")

var player: Node = null

func _ready():
	if has_node("../../Player"):
		player = get_node("../../Player")
	else:
		player = null
	update_hearts()


func update_hearts():
	var container = $HBoxContainer
	# Clear old children
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
##
	##heart_sprites.clear()
	var new_broken = false
	if not player:
		return
	for i in player.max_hp:
		if i < player.current_hp:
			var heart = Sprite2D.new()
			heart.texture = FULL_HEART_TEXTURE
			heart.position = Vector2(i * 20, 0)
			container.add_child(heart)
		elif not new_broken:
			new_broken = true
			var broken_heart = BROKEN_HEART_ANIMATION.instantiate()
			broken_heart.position = Vector2(i * 20, 0)
			container.add_child(broken_heart)
		else:
			var heart = Sprite2D.new()
			heart.texture = EMPTY_HEART_TEXTURE
			heart.position = Vector2(i * 20, 0)
			container.add_child(heart)
