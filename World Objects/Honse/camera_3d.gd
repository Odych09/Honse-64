extends Camera3D

# Σύρε εδώ τη σφαίρα σου από τον Inspector
@export var ball_target: RigidBody3D

# Η σταθερή απόσταση που θα έχει η κάμερα από τη σφαίρα (X, Y, Z)
var offset: Vector3

func _ready() -> void:
	if ball_target:
		# Υπολογίζει αυτόματα την αρχική απόσταση με βάση το πού τις τοποθέτησες στον editor
		offset = global_position - ball_target.global_position

func _physics_process(_delta: float) -> void:
	if ball_target:
		# Ακολουθεί τη σφαίρα διατηρώντας την ίδια ακριβώς απόσταση, χωρίς να στρίβει
		global_position = ball_target.global_position + offset
