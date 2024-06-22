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
extends Path3D

# MultiScatter is the main node of this plugin. It provides a Path3D (Polygon)
# to set up the area where the MultiMeshes shall spawn.
class_name  MultiScatter

# The amount of multimeshes 
@export var amount : int = 100

# Seed for the RandomNumberGenerator. Setting up the seed makes the generated
# positions of each mesh deterministical.
@export var seed : int = 0

# the min-max value how high / deep the meshes are floating (if floating)
@export var floating_min_max_y : float = 50.0

# helper to calculate the proportion percentage.
var _sum_proportion = 0

# Properties used for rayCast to calculate the height of the mesh Instance if it
# shall be dropped on floor.

# Physics Space to perform the raycast
@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

# collision mask to select the layer of the ray cast.
@export_flags_3d_physics var collision_mask := 0x1:
	get: return collision_mask
	set(value):
		collision_mask = value
	
# Debug Messages on/off	
@export_group("Debug")
@export var debugMessages = false

func _ready():
	self.curve_changed.connect(_on_curve_changed)

# Helper function for debugging.	
func _debug(message):
	if debugMessages:
		print("YAMMS: MultiScatter:  " + message)

# Generate the MultiScatter
func do_generate():
	_debug("Starting to generate.")
	_debug("Amount: %s" %amount)
	_debug("Seed: %s" %seed)
	_debug("Floating Min Max: %s" %floating_min_max_y)
	_debug("Collision Mask: %s" %collision_mask)

	# init RandomNumberGenerator for placing the MultiMeshes randomly.
	var random = RandomNumberGenerator.new()
	random.state = 0	
	random.set_seed(seed)

	# Retrieve data from chilren MultiScatterItems
	var entries = _get_scatter_items_data()
	
	# Iterate through each MultiScatterItem entry and generate
	# the positions for the MultiMesh instances.
	for entry in entries:
		
		# Instantiate the required PlacementMode.
		var pm : PlacementMode
		var placement_mode = entry["PlacementMode"]
		if placement_mode == PlacementMode.Mode.FLAT:
			pm = PMFlat.new(self)
			_debug("PlacementMode: FLAT")	
		elif placement_mode == PlacementMode.Mode.FLOATING:
			pm = PMFloating.new(self)
			_debug("PlacementMode: FLOATING")	
		elif placement_mode == PlacementMode.Mode.DROP_ON_FLOOR:
			pm = PMDropOnFloor.new(self)
			_debug("PlacementMode: DROP_ON_FLOOR")
		elif placement_mode == PlacementMode.Mode.DROP_ON_CEILING:
			pm = PMDropOnCeiling.new(self)
			_debug("PlacementMode: DROP_ON_Ceiling")
		
		_debug("Calling PlacementMode.init_placement")
		
		# Initialize PladementMode with data.
		pm.init_placement(
			curve,
			collision_mask,
			-floating_min_max_y,
			floating_min_max_y,
			debugMessages,
			random
		)
	
		# ..and generated
		_debug("Calling PlacementMode.do_generate")
		pm.do_generate(
			entry,
			amount,
			_sum_proportion,
			_get_exclude_data(),
			global_position, 
			_space
		)


# Create the transform of the Mesh
# - apply rotation, scale and position		
func _create_transform(pos : Vector3, rotation : Vector3, scale : Vector3):
	var transform = Transform3D(Basis(), Vector3())\
		.rotated(Vector3.RIGHT, rotation.x)\
		.rotated(Vector3.FORWARD, rotation.y)\
		.rotated(Vector3.UP, rotation.z)\
		.scaled(scale)\
		.translated(pos)
	return transform
	
# Gets all data from the child ScatterItems.
# Returns an array with Dictionary entries:
#  - Proportion
#  - RandomRotation
#  - RandomScale
#  - MaxRotation
#  - MaxScale
#  - PlacementMode
#  - ScatterItem
#  - additionalScene
#  - targetNode
#
#
# Also: Sums up proportion which is being used for the calculation of the 
# percentage of each proportion.
func _get_scatter_items_data():
	_sum_proportion = 0
	var result = []
	for child in get_children():
		if child is MultiScatterItem:
			var scatter_item = child as MultiScatterItem
			var entry = {}
			entry["Proportion"] = scatter_item.proportion
			entry["RandomRotation"] = scatter_item.randomize_rotation
			entry["RandomScale"] = scatter_item.randomize_scale
			entry["MaxRotation"] = scatter_item.max_degrees
			entry["MaxScale"] = scatter_item.max_scale
			entry["PlacementMode"] = scatter_item.placement_mode
			entry["ScatterItem"] = scatter_item
			if scatter_item.enableAdditionalScene == true:
				entry["additionalScene"] = scatter_item.additionalScene
				entry["targetNode"] = scatter_item.targetNode
			else:
				entry["additionalScene"] = null
				entry["targetNode"] = null
			
			
			result.append(entry)
			_sum_proportion += scatter_item.proportion
	return result
	
	
func _get_exclude_data():
	var result = []
	for child in get_children():
		if child is MultiScatterExclude:
			var exclude = child as MultiScatterExclude
			result.append(exclude)
	return result
	
# Count number of scatter items
func _count_scatter_items():
	var found : int = 0
	for child in get_children():
		if child is MultiScatterItem:
			found += 1
	
	return found

# Configuration check: Do I have at least one MultiScatterItem as child?
func _check_scatter_items():
	return (_count_scatter_items() > 0)

# Configuration check: Do I have enough polygon points?
func _check_polygon() -> bool:
	var nr_points = curve.get_point_count ()
	return _check_polygon_nr(nr_points)

# Configuration check: Do I have enough polygon points?
# - at least 3 points expected to span a plane	
func _check_polygon_nr(nr_points) -> bool:
	return (nr_points > 2)

# Curve changed. Trigger a check of the configuration warning, so that the
# exclamation mark is shown in case there are not enough points in polygon.
func _on_curve_changed():
	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)

# Get config warnings if something is missing
# or empty warning array if erverything is OK.
func _get_configuration_warnings() -> PackedStringArray:
	var return_value = []
	if not _check_polygon():
		return_value.append("Not enough points in polygons to span a plane. At least 3 poits expected.")		
	
	if not _check_scatter_items():
		return_value.append("At least one MultiScatterItem is required.")
		
	return return_value

