extends CharacterBody3D

@export var WaterWaveEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_water_wave_stamp.tscn")
@export var GrassTrailEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_grass_trail_stamp.tscn")
@export var DirtFootprintEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_dirt_footprint_stamp.tscn")

@export var WaterHeight = 6.5

@export var TrailParticleSpawnMinimumVelocity : float = 0.5;
@export var TrailParticleSpawnRate : float = 0.05;

@export var FootPrintWidth : float  = 0.5

@export var BaseDisplacementMesh : MeshInstance3D

@export var RotationSensitivity = 0.1
@export var MoveSpeed = 5.0
@export var CameraTarget : Node3D

var currentTrailSpawnTime : float = 0.0
var currentFootstepSpawnTime : float = 0.0
var lastStepRight : bool = false
const JUMP_VELOCITY = 4.5


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		rotate_y(deg_to_rad(-event.relative.x*RotationSensitivity))
		
		CameraTarget.rotate_x(deg_to_rad(-event.relative.y*RotationSensitivity))
		#CameraTarget.rotation_degrees.z = clampf(CameraTarget.rotation_degrees.z, 20.0, -20.0)
		
	elif (event.is_action_pressed("ui_cancel")):
		if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not is_on_floor():
		BaseDisplacementMesh.set_instance_shader_parameter("ParticleOpacity", 0.0)
	else:
		currentFootstepSpawnTime += delta
		if (currentFootstepSpawnTime >= 0.2):
			currentFootstepSpawnTime -= 0.2
			var newPosition : Vector3 = global_position
			newPosition += global_transform.basis.x * (FootPrintWidth / 2) * (-1 if lastStepRight else 1)
			
			
			var footstepeffect = DirtFootprintEffect.instantiate() as Node3D
			get_parent().add_child(footstepeffect)
			footstepeffect.global_position = newPosition
			footstepeffect.global_rotation.y = global_rotation.y
			footstepeffect.scale.x *= -1 if footstepeffect else 1
			lastStepRight = !lastStepRight
		
		if (velocity.length() > TrailParticleSpawnMinimumVelocity):
			currentTrailSpawnTime += delta
			if (currentTrailSpawnTime >= TrailParticleSpawnRate):
				currentTrailSpawnTime -= TrailParticleSpawnRate
				var waveeffect = (WaterWaveEffect if global_position.y < WaterHeight else GrassTrailEffect).instantiate() as Node3D
				get_parent().add_child(waveeffect)
				waveeffect.global_position = global_position
				waveeffect.global_rotation.y = global_rotation.y
		
		BaseDisplacementMesh.set_instance_shader_parameter("ParticleOpacity", 1.0)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * MoveSpeed
		velocity.z = direction.z * MoveSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, MoveSpeed)
		velocity.z = move_toward(velocity.z, 0, MoveSpeed)
	
	
	move_and_slide()
