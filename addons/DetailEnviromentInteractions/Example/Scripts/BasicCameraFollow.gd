extends Camera3D

@export var playerBody : Node3D
@export var offsetDistanceHorizontal : float = 5
@export var offsetDistanceVertical : float = 1
@export var movementSpeed : float = 5


func _physics_process(delta: float) -> void:
	var newTarget : Vector3 = playerBody.global_position
	newTarget += playerBody.global_transform.basis.z * offsetDistanceHorizontal
	newTarget += playerBody.global_transform.basis.y * offsetDistanceVertical
	global_position = global_position.lerp(newTarget, movementSpeed * delta)
	look_at(playerBody.global_position)
