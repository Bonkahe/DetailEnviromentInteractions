# MIT License
# 
# Copyright (c) 2023 Mattiny
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
@tool
extends MultiMeshInstance3D
class_name MultiScatterItem

# The MultiScatterItem is a MultiMesh3D.
# 
# Additionally it holds some parameters how the mesh instances shall be placed.
# Placing the mesh instances then is done by MultiScatter.



# Proportion how many mesh instances shall be placed. This is useful if a
# MultiScatter has more than one MultiScatterItem. 
#
# From the proportion of this MultiScatterItem and the proportion of other 
# MultiScatterItem the percentage of each MultiScatterItem will be calculated. 
# Then the percentage of the MultiScatter amount results in the actual amount 
# for this MultiScatterItem
@export var proportion : int = 100 :
	set(value):
		proportion = value

# import the PlacementMode class
const PlacementMode = preload("res://addons/yamms/PlacementMode.gd") 
# PlacementModes - Default = Drop on Floor:
@export var placement_mode : PlacementMode.Mode = PlacementMode.Mode.DROP_ON_FLOOR

@export_group("Random Rotation")
@export var randomize_rotation : bool = false
@export var max_degrees : Vector3 

@export_group("Random Scale")
@export var randomize_scale : bool = false
@export var max_scale : Vector3 = Vector3(1.0, 1.0, 1.0)

@export_group("Additional Scene")
@export var enableAdditionalScene : bool = false
@export var targetNode: Node3D
@export var additionalScene: PackedScene


@export_group("Excludes")
@export var exclude : Array[MultiScatterExclude] = []

func _ready():
	pass

# sets the actual amount of the meshes
func set_amount(number):
	self.multimesh.instance_count = number

# sets the transform of one instance of the multimesh
# - index - The index of the mesh
# - transform - The transform containing position, rotation and scale.
func do_transform(index : int, transform : Transform3D):

	self.multimesh.set_instance_transform(index, transform)
	#self.multimesh.set_instance_transform(index, Transform3D(Basis(), pos))
	
func _get_configuration_warnings() -> PackedStringArray:
	if not self.multimesh or not self.multimesh.mesh:
		return ["No MultiMesh is set up."]
	else:
		if (targetNode == null and additionalScene != null):
			return ["Additional scene is set up, but no target node."]	
		if (targetNode != null and additionalScene == null):
			return ["Target node is set up, but no additional scene."]	
		return []

