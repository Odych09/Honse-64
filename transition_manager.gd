extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func change_scene_with_transition(target_scene_path: String) -> void:
	var tween = create_tween()
	
	# 1. Close the circle (Animate progress to 1.0)
	tween.tween_property(color_rect.material, "shader_parameter/_Progress", 1.0, 0.8)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	get_tree().change_scene_to_file(target_scene_path)
	
	await get_tree().create_timer(0.1).timeout
	
	# 3. Open the circle back up (Animate progress back to 0.0)
	var tween_open = create_tween()
	tween_open.tween_property(color_rect.material, "shader_parameter/_Progress", 0.0, 0.8)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
