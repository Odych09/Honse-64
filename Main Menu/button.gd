extends Button

const COLOR_HOVER: Color = Color("f5b201")
const COLOR_NORMAL: Color = Color.WHITE

func _on_mouse_entered() -> void:
	modulate = COLOR_HOVER
	$AudioStreamPlayer2D.play()

func _on_mouse_exited() -> void:
	modulate = COLOR_NORMAL
