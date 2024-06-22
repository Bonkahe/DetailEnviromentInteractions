@tool
# Having a class name is required for a custom node.
class_name VisualShaderNodeSampleDetailEffectsLayerShaderNode
extends VisualShaderNodeCustom


func _get_name() -> String:
	return "DetailEffectsSample"


func _get_category() -> String:
	return "BonkaheEffects"


func _get_description() -> String:
	return "Returns the current value of the details effect layer"


func _get_return_icon_type() -> PortType:
	return PORT_TYPE_VECTOR_4D


func _get_input_port_count() -> int:
	return 0


func _get_input_port_name(_port: int) -> String:
	return ""


func _get_input_port_type(_port: int) -> PortType:
	return PORT_TYPE_SCALAR


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
		return output_vars[0] + " = SampleDetailEffectsLayer((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);"
	elif (type == VisualShader.TYPE_VERTEX):
		return output_vars[0] + " = SampleDetailEffectsLayer(NODE_POSITION_WORLD + VERTEX);"
	else:
		return ""
