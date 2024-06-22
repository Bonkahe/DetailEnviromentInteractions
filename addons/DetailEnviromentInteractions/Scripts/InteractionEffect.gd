extends MeshInstance3D

@export var Duration : float = 5.0
@export var EndScale : float = 1.0
@export var AlphaOverLife : Curve

var currentTime : float = 0
var originScale : Vector3

func _ready() -> void:
	originScale = scale
	if (originScale == Vector3.ZERO):
		originScale = Vector3.ONE * 0.001

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	currentTime += delta
	if (currentTime >= Duration):
		queue_free()
		return
	
	set_instance_shader_parameter("ParticleOpacity", AlphaOverLife.sample(currentTime / Duration))
	scale = originScale.lerp(Vector3.ONE * EndScale, currentTime / Duration)
