extends Node3D

# This allows you to add as many different chunk scenes as you want in the inspector!
@export var chunk_templates: Array[PackedScene] = []
@export var player_ball: RigidBody3D 

var chunk_length: float = 60.0 
var max_chunks_on_screen: int = 5
var spawned_chunks: Array = []
var next_spawn_z: float = 0.0

func _ready() -> void:
	if chunk_templates.is_empty():
		push_error("Your Chunk Templates array is empty! Add your chunk scenes in the inspector.")
		return
		
	# Always spawn clean, empty runways at the very start so the player can accelerate safely
	for i in range(max_chunks_on_screen):
		spawn_next_chunk(i == 0 or i == 1) # First 2 chunks will force a clean runway

func _process(_delta: float) -> void:
	if not player_ball or spawned_chunks.is_empty():
		return
		
	var oldest_chunk = spawned_chunks[0]
	if player_ball.global_position.z < oldest_chunk.global_position.z - chunk_length:
		spawned_chunks.pop_front()
		oldest_chunk.queue_free()
		
		# Spawn a completely random chunk out in front
		spawn_next_chunk(false)

func spawn_next_chunk(force_clean: bool) -> void:
	var selected_scene: PackedScene
	
	# If we need a clean start, or if you only have 1 chunk setup, default to index 0
	if force_clean or chunk_templates.size() == 1:
		selected_scene = chunk_templates[0]
	else:
		# Pick a completely random scene from your array list (Runway, Boxes, or Ramp)
		var random_index = randi() % chunk_templates.size()
		selected_scene = chunk_templates[random_index]
		
	var new_chunk = selected_scene.instantiate() as Node3D
	new_chunk.global_position = Vector3(0, 0, next_spawn_z)
	add_child(new_chunk)
	
	spawned_chunks.append(new_chunk)
	next_spawn_z -= chunk_length
