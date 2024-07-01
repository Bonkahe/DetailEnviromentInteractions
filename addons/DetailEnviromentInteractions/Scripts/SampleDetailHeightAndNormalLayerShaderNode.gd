@tool
# Having a class name is required for a custom node.
class_name VisualShaderNodeSampleHeightAndNormalLayerShaderNode
extends VisualShaderNodeCustom


func _get_name() -> String:
	return "DetailEffectsHeightAndNormalSample"


func _get_category() -> String:
	return "BonkaheEffects"


func _get_description() -> String:
	return "Returns the height, and normals of a given channel"


func _get_return_icon_type() -> PortType:
	return PORT_TYPE_VECTOR_4D


func _get_input_port_count() -> int:
	return 1


func _get_input_port_name(_port: int) -> String:
	return "SelectedChannel"


func _get_input_port_type(_port: int) -> PortType:
	return PORT_TYPE_SCALAR_INT


func _get_output_port_count() -> int:
	return 1


func _get_output_port_name(_port: int) -> String:
	return "Result"


func _get_output_port_type(_port: int) -> PortType:
	return PORT_TYPE_VECTOR_4D


func _get_global_code(_mode: Shader.Mode):
	return """
		#include "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc"
	"""

func _get_code(_input_vars: Array[String], output_vars: Array[String],
		_mode: Shader.Mode, type: VisualShader.Type) -> String:
	if (type == VisualShader.TYPE_FRAGMENT):
		return output_vars[0] + " = RetrieveNormalMapAndHeight((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, " + _input_vars[0] + ");"
	elif (type == VisualShader.TYPE_VERTEX):
		return output_vars[0] + " = RetrieveNormalMapAndHeight(NODE_POSITION_WORLD + VERTEX, " + _input_vars[0] + ");"
	else:
		return ""
