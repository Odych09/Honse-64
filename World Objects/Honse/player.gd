extends RigidBody3D


@export var rolling_force: float = 40.0
@export var jump_force: float = 12.0
@export var milestone_step: int = 10 

#@onready var trail: GPUParticles3D = $"../trail"
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var speed_label: Label = $CameraPivot/Camera3D/UserInterface/SpeedLabel
@onready var slam: GPUParticles3D = $slam
@onready var slam_area: Area3D = $SlamArea

# Grappling hook
@export var grapple_force: float = 70.0
@export var grapple_distance: float = 50.0

@onready var grapple_line: MeshInstance3D = $GrappleLine
@export var wall_jump_force: float = 18.0
@export var wall_jump_push: float = 12.0
@export var wall_check_distance: float = 1.2

@export var dash_force: float = 25.0
@export var dash_cooldown: float = 1.0
@export var slam_force := 60.0

var was_on_floor := false
var is_ground_slamming := false
var slam_start_height := 0.0

var can_dash := true
var wall_normal := Vector3.ZERO
var touching_wall := false

var grappling := false
var grapple_point := Vector3.ZERO

var grapple_mesh := ImmediateMesh.new()
var grapple_material := StandardMaterial3D.new()

# Speed popup variables
var last_speed_milestone: int = 0
var speed_tween: Tween
var is_animating_rainbow: bool = false
var rainbow_hue: float = 0.0


func _ready() -> void:
	
	# Setup rope
	grapple_line.mesh = grapple_mesh
	
	grapple_material.albedo_color = Color.WHITE
	grapple_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _physics_process(_delta: float) -> void:

	# Movement Input Logic
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var forward := camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x
	
	forward.y = 0.0
	right.y = 0.0
	
	forward = forward.normalized()
	right = right.normalized()
	
	var move_direction := (forward * input_dir.y + right * input_dir.x).normalized()

	if move_direction.length() > 0:
		apply_central_force(move_direction * rolling_force)


	# Jump
	if Input.is_action_just_pressed("jump") and abs(linear_velocity.y) < 0.1:
		apply_central_impulse(Vector3.UP * jump_force)


	# Grapple physics
	if grappling:

		var direction = grapple_point - global_position
		var distance = direction.length()

		if distance < 2.0:
			grappling = false
		else:
			apply_central_force(direction.normalized() * grapple_force)


	# Speedometer
	var total_speed := linear_velocity.length()
	var current_speed_mph := int(total_speed * 2.237)
	var current_milestone := (current_speed_mph / milestone_step) * milestone_step


	#if current_speed_mph > 150:
		#trail.emitting = true
	#else:
		#trail.emitting = false


	if current_milestone != last_speed_milestone:
		last_speed_milestone = current_milestone
		trigger_juicy_text_popup(current_milestone)


	# Trail rotation
	#if trail and total_speed > 0.5:
#
		#var target_position = trail.global_position - linear_velocity
#
		#trail.look_at(target_position, Vector3.UP)
#
		#trail.rotate_object_local(Vector3.UP, deg_to_rad(90.0))
#
		#trail.speed_scale = clamp(total_speed / 20.0, 0.5, 3.0)
	var on_floor = abs(linear_velocity.y) < 0.1

	if is_ground_slamming and on_floor and !was_on_floor:

		is_ground_slamming = false

		var fall_distance = slam_start_height - global_position.y

		ground_slam_land(fall_distance)

	was_on_floor = on_floor


func apply_slam_force(force: float) -> void:

	var bodies = slam_area.get_overlapping_bodies()

	for body in bodies:

		if body is RigidBody3D and body != self:

			var direction = body.global_position - global_position
			direction.y = 0.4

			var dist = global_position.distance_to(body.global_position)

			# falloff (closer = stronger)
			var strength = clamp(1.0 - (dist / 8.0), 0.2, 1.0)

			var impulse = direction.normalized() * force * strength

			body.apply_central_impulse(impulse)



func ground_slam_land(fall_distance: float) -> void:

	print("Fall distance:", fall_distance)

	# base effects always happen

	# small slam
	if fall_distance > 5:
		slam.amount = 32
		camera_pivot.add_camera_shake(0.2)
		apply_slam_force(30.0)

	# medium slam
	if fall_distance > 10:
		camera_pivot.add_camera_shake(0.5)
		apply_slam_force(50.0)
		slam.amount = 64
		# small time slow for impact feel
		Engine.time_scale = 0.3
		await get_tree().create_timer(0.08).timeout
		Engine.time_scale = 1.0

	# BIG slam
	if fall_distance > 20:
		slam.amount = 64
		camera_pivot.add_camera_shake(1.0)
		apply_slam_force(100.0)
	
		# stronger shock feel
		Engine.time_scale = 0.15
		await get_tree().create_timer(0.12).timeout
		Engine.time_scale = 1.0

		# extra burst
		apply_slam_force(45.0)
	slam.emitting = true



func trigger_juicy_text_popup(speed_value: int) -> void:
	if !speed_label:
		return
	
	# 1. Update text content
	speed_label.text = str(speed_value) + " MPH!"
	
	# FORCE THE PIVOT TO STAY DEAD CENTER
	speed_label.pivot_offset = speed_label.size / 2.0
	
	# 2. Kill any running animation pipeline
	if speed_tween and speed_tween.is_valid():
		speed_tween.kill()
	
	# 3. Create a fresh parallel tween
	speed_tween = create_tween().set_parallel(true)
	
	# RESET properties
	speed_label.scale = Vector2(1.0, 1.0)
	speed_label.modulate.a = 1.0 
	
	# Enable the rainbow logic processor
	is_animating_rainbow = true

	# ANIMATION A: The Big Burst Scale
	speed_tween.tween_property(
		speed_label,
		"scale",
		Vector2(2.5, 2.5),
		0.08
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ANIMATION B: Settle Scale down smoothly
	speed_tween.chain().tween_property(
		speed_label,
		"scale",
		Vector2(1.2, 1.2),
		0.12
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# ANIMATION C: The Disappearing Act
	speed_tween.chain().tween_interval(0.3)
	
	# Fade out alpha over 0.15 seconds
	var fade_tween = speed_tween.chain().tween_property(
		speed_label,
		"modulate:a",
		0.0,
		0.15
	)
	
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Turn off rainbow calculations when finished
	fade_tween.finished.connect(func():
		is_animating_rainbow = false
	)

func _process(delta: float) -> void:


	# Rainbow speed text
	if is_animating_rainbow and speed_label:

		rainbow_hue += delta * 2.0

		if rainbow_hue > 1.0:
			rainbow_hue -= 1.0


		var rainbow_color := Color.from_hsv(
			rainbow_hue,
			0.9,
			1.0
		)


		speed_label.modulate.r = rainbow_color.r
		speed_label.modulate.g = rainbow_color.g
		speed_label.modulate.b = rainbow_color.b


	# Draw grapple rope
	update_grapple_visual()
	check_wall()

func _unhandled_input(_event: InputEvent) -> void:

	if Input.is_action_pressed("restart"):
		get_tree().reload_current_scene()


	if Input.is_action_just_pressed("grapple"):
		shoot_grapple()


	if Input.is_action_just_released("grapple"):
		grappling = false

	if Input.is_action_just_pressed("dash"):
		dash()

	if Input.is_action_just_pressed("ground_slam") and abs(linear_velocity.y) > 0.1:
		is_ground_slamming = true
		slam_start_height = global_position.y

		linear_velocity.x *= 0.3
		linear_velocity.z *= 0.3

		apply_central_impulse(Vector3.DOWN * slam_force)

	if Input.is_action_just_pressed("jump"):

		if touching_wall:

			linear_velocity.y = 0

			var jump_direction = wall_normal * wall_jump_push + Vector3.UP * wall_jump_force

			apply_central_impulse(jump_direction)

		elif abs(linear_velocity.y) < 0.1:

			apply_central_impulse(Vector3.UP * jump_force)


func shoot_grapple():

	var from = camera.global_position

	# Camera forward direction
	var direction = -camera.global_transform.basis.z

	var to = from + direction * grapple_distance

	var query = PhysicsRayQueryParameters3D.create(from, to)

	# Ignore the ball itself
	query.exclude = [self]

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		grapple_point = result.position
		grappling = true



func update_grapple_visual():

	grapple_mesh.clear_surfaces()


	if grappling:

		grapple_mesh.surface_begin(
			Mesh.PRIMITIVE_LINES,
			grapple_material
		)


		# Start point (ball)
		grapple_mesh.surface_add_vertex(Vector3.ZERO)


		# End point (wall)
		grapple_mesh.surface_add_vertex(
			to_local(grapple_point)
		)


		grapple_mesh.surface_end()

func check_wall():

	touching_wall = false
	wall_normal = Vector3.ZERO

	var space_state = get_world_3d().direct_space_state

	var directions = [
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3.LEFT,
		Vector3.RIGHT
	]

	for dir in directions:

		var from = global_position
		var to = global_position + dir * wall_check_distance

		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]

		var result = space_state.intersect_ray(query)

		if result:
			touching_wall = true
			wall_normal = result.normal
			return

func dash():

	if !can_dash:
		return

	can_dash = false

	var dash_direction = -camera.global_transform.basis.z
	dash_direction.y = 0
	dash_direction = dash_direction.normalized()

	apply_central_impulse(dash_direction * dash_force)

	await get_tree().create_timer(dash_cooldown).timeout

	can_dash = true
