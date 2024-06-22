@tool
extends EditorPlugin


func _enter_tree() -> void:
	var globalShaderVariables : Array[StringName] = RenderingServer.global_shader_parameter_get_list()
	if !globalShaderVariables.has("GrassDetailViewportTexture"):
		printerr("DetailEnviromentInteractions: Missing global shader variable: GrassDetailViewportTexture(Sampler2D)")
	if !globalShaderVariables.has("GrassDetailViewportTextureCornerPosition"):
		printerr("DetailEnviromentInteractions: Missing global shader variable: GrassDetailViewportTextureCornerPosition(Vector3)")
	if !globalShaderVariables.has("GrassDetailViewportTextureSize"):
		printerr("DetailEnviromentInteractions: Missing global shader variable: GrassDetailViewportTextureSize(Float)")



func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
