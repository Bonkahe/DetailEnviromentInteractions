extends CharacterBody3D

@export var WaterWaveEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_water_wave_stamp.tscn")
@export var GrassTrailEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_grass_trail_stamp.tscn")
@export var DirtFootprintEffect : PackedScene = preload("res://addons/DetailEnviromentInteractions/Example/PackedScenes/detail_effect_dirt_footprint_stamp.tscn")

@export var WaterHeight = 6.5

@export var TrailParticleSpawnMinimumVelocity : float = 0.5;
@export var TrailParticleSpawnRate : float = 0.05;

@export var FootPrintWidth : float  = 0.5

@export var BaseDisplacementMesh : MeshInstance3D

@export var MoveSpeed = 5.0
@export var MovementBaseDuration : float = 2.0
@export_range(0,1) var MovementDurationRandomness : float = 0.5

var currentTrailSpawnTime : float = 0.0
var currentFootstepSpawnTime : float = 0.0
var lastStepRight : bool = false

var currentMovementVector : Vector3
var remainingMovementTime : float


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
	remainingMovementTime -= delta
	
	if (remainingMovementTime <= 0):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		remainingMovementTime = MovementBaseDuration - (rng.randf_range(0.0, MovementDurationRandomness) * MovementBaseDuration)
		
		currentMovementVector = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
	
	velocity.x = currentMovementVector.x * MoveSpeed
	velocity.z = currentMovementVector.z * MoveSpeed
	
	look_at(global_position + currentMovementVector, Vector3.UP);
	
	move_and_slide()
