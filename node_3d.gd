extends Node3D

@export var target_node: RigidBody3D
@export var mouse_sensitivity: float = 0.005
var shake_strength := 0.0
var shake_decay := 5.0
var shake_offset := Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_as_top_level(true)

func _physics_process(delta: float) -> void:
	if target_node:
		var target_pos = target_node.global_position

		# Smooth follow
		global_position = global_position.lerp(target_pos, 0.2)

	# decay shake over time
	shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)

	# generate shake offset
	if shake_strength > 0.01:
		shake_offset = Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		shake_offset = Vector3.ZERO

	# apply final position
	global_position += shake_offset

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate left/right
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Rotate up/down
		rotation.x = clamp(
			rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(-85),
			deg_to_rad(40)
		)

func add_camera_shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)
