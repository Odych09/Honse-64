extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _process(_delta: float) -> void:
	animation_player.play("HONSE")
	await animation_player.animation_finished
	await get_tree().create_timer(randf_range(1,3)).timeout


func _on_button_3_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	TransitionManager.change_scene_with_transition("res://testing.tscn")
