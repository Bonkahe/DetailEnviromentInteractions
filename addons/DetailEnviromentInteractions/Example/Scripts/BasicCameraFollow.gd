extends Camera3D

@export var playerBody : Node3D
@export var offsetDistanceHorizontalMin : float = 5
@export var offsetDistanceHorizontalMax : float = 15
@export var offsetDistanceVertical : float = 1
@export var movementSpeed : float = 5

var currentHorizontalOffset : float

func _ready() -> void:
	currentHorizontalOffset = 0.5

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			currentHorizontalOffset = clampf(currentHorizontalOffset - 0.05, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			currentHorizontalOffset = clampf(currentHorizontalOffset + 0.05, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	var newTarget : Vector3 = playerBody.global_position
	newTarget += playerBody.global_transform.basis.z * lerpf(offsetDistanceHorizontalMin, offsetDistanceHorizontalMax, currentHorizontalOffset)
	newTarget += playerBody.global_transform.basis.y * offsetDistanceVertical
	global_position = global_position.lerp(newTarget, movementSpeed * delta)
	look_at(playerBody.global_position)
