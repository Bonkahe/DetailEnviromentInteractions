extends SubViewport

@export var PlayerModel : Node3D
@export var RepositionRate : float = 0.2
@export var SnapStep : float = 2.0 #should be typically a multiple of 2 for even stepping of pixels

var lastPosition : Vector3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# move to plugin initialization later.
	#var globalShaderVariables : Array[StringName] = RenderingServer.global_shader_parameter_get_list()
	#print(globalShaderVariables)
	#if (!globalShaderVariables.has("GrassDetailViewportTexture") 
	#|| !globalShaderVariables.has("GrassDetailViewportTextureCornerPosition") 
	#|| !globalShaderVariables.has("GrassDetailViewportTextureSize")):
		#printerr("Missing global shader variables for detail effects.")
		#queue_free()
		#return
	#
	RenderingServer.global_shader_parameter_set("GrassDetailViewportTexture", get_texture())
	var size = get_camera_3d().size
	RenderingServer.global_shader_parameter_set("GrassDetailViewportTextureSize", size)
	RenderingServer.global_shader_parameter_set("GrassDetailViewportTextureCornerPosition", get_camera_3d().global_position - Vector3(size / 2, 0, size / 2))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (PlayerModel.global_position.distance_to(lastPosition) > RepositionRate):
		lastPosition = PlayerModel.global_position
		lastPosition.x = snappedf(lastPosition.x, SnapStep)
		lastPosition.y = snappedf(lastPosition.y + 1000.0, SnapStep)
		lastPosition.z = snappedf(lastPosition.z, SnapStep)
		
		get_camera_3d().global_position = lastPosition
		
		var size = get_camera_3d().size
		RenderingServer.global_shader_parameter_set("GrassDetailViewportTextureSize", size)
		RenderingServer.global_shader_parameter_set("GrassDetailViewportTextureCornerPosition", get_camera_3d().global_position - Vector3(size / 2, 0, size / 2))
