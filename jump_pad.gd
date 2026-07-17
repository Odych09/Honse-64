extends Node3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		gpu_particles_3d.emitting = true
		body.apply_central_impulse(Vector3.UP * 20)
		await get_tree().create_timer(0.5).timeout
		body.rolling_force = 40.0
