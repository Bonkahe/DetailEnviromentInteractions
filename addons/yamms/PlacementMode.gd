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
extends Node
class_name PlacementMode
enum Mode {FLAT, DROP_ON_FLOOR, FLOATING, DROP_ON_CEILING}

var _curve : Curve3D
var _nr_points : int
var _coll_mask

var _min_offset_y : float
var _max_offset_y : float

var _debug_messages : bool = false

# helper to calculate the proportion percentage.
var _sum_proportion = 0
var _multiScatter

var _random : RandomNumberGenerator

func _init(multiscatter):
	_multiScatter = multiscatter

func _debug(message):
	if _debug_messages:
		print("YAMMS: PlacementMode:  " + message)

func init_placement(
		curve : Curve3D, 
		collision_mask, 
		min_offset_y : float, 
		max_offset_y : float,
		debug_messages : bool, 
		random : RandomNumberGenerator):
	_random = random
	_debug_messages = debug_messages
	_curve = curve
	_nr_points = _curve.get_point_count ()
	_coll_mask = collision_mask
	_min_offset_y = min_offset_y
	_max_offset_y = max_offset_y
	_debug("Nr of points in polygon: %s" %_nr_points)

func _check_polygon_nr() -> bool:
	return (_nr_points > 2)
	
func generate_random(min, max):
	return _random.randf_range(min, max)

# Generate the positions for all MultiMesh instances.
#  - ScatterData = The data for the ScatterItems. 
#    See MultiScatter._get_Scatter_Data for more details.
#  - amount = the total number of all items to be placed
#  - sum_proportion = The sum of all proportions, needed to calculate the percentage
#                     of items for each MultiScatterItem
#  - excludes = List of all exclude-data
#  - global_position = The position of the MultiScatter. Needed as offset for
#                      for calculating the position of each MultiMesh item instance.
#  - Space = PhysicsDirectSpaceState3D used for a ray-cast when calculating the
#            item's position.
func do_generate(
		scatterData, 
		amount : int,  
		sum_proportion : int, 
		excludes, 
		global_position,
		space):
	if _check_polygon_nr():
		_debug("Starting to generate.")
		
		# Get the coordinates from the first point as reference for the min max
		# values.
		var point = _curve.get_point_position(0)
		var min_x = point.x
		var max_x = point.x
		var min_y = point.z
		var max_y = point.z
		
		var avg_height = 0.0
		
		# Save all point coordinates in a 2D Polygon for the "inside polygon check"
		var polygon = []
		
		# Get the min max value of the x-z coordinates in 3D space.
		# and append to 2D polygon
		# and add height to average height.
		#
		# MultiMesh instances are supposed to spawn within the min-max values.
		# In case the spawn position collides with an exlude area, the instance
		# wont be set and a new position will be generated until it can be placed.
		for i in _nr_points:
			point = _curve.get_point_position(i)
			avg_height += point.y
			polygon.append(Vector2(point.x, point.z))
			if point.x < min_x:
				min_x = point.x
			if point.x > max_x:
				max_x = point.x
			if point.z < min_y:
				min_y = point.z
			if point.z > max_y:
				max_y = point.z

		# get the average of the height
		avg_height = avg_height / _nr_points
		_debug("Average height: %s" %avg_height)
		
		_debug("Generating positions for %s MultiScatterItems." %scatterData.size())
		
		var scatter_item = scatterData["ScatterItem"] as MultiScatterItem
		var targetNode = scatterData["targetNode"]
		var additionalScene = scatterData["additionalScene"]
		_debug("--- MultiScatterItem %s" %scatter_item.name)
			
		# Remove all children of the targetNode because locations will be 
		# generated in a new run.
		_clear_target_node(targetNode)
			
		# Calculate the amount of mesh items depending on the amount and proportion
		var proportion = scatterData["Proportion"]
		_debug("MultiScatter Proportion: %s" %proportion)
		var percentage : float = (float(100) * proportion) / sum_proportion
		_debug("Percentage for MultiScatterItem: %s" %percentage)
		var amount_for_proportion : int = float(amount) / 100 * percentage
		_debug("Amount for MultiScatterItem: %s" %amount_for_proportion)
			
		# set the spawn data to the MultiMeshItem to prepare generation
		# of meshes.
		scatter_item.set_amount(amount_for_proportion)
			
		# Now generate new x-z coordinates for each mesh in the MultiMeshInstance.
		# (height is calculated separately, depending on the placement mode)
		for index in range(amount_for_proportion):
			
			# Do as long until the random 2D coordinates are inside the polygon.
			var is_point_in_polygon = false
				
			var attempts : int = 0 # Nr of attempts to place mesh inside of the polygon
			while not is_point_in_polygon:
				attempts += 1
				if attempts == 100:
					var message = "Cannot drop MultiMesh. Please check: " \
						+ "1) Is the polygon area large enough? " \
						+ "2) Is the whole polygon area hidden by an exclude area? " \
						+ "3) Drop on Floor: is there a large object with collision object underneath?" \
						+ "4) Drop on Ceiling: is there a large object with collision object above?"
						
					_debug(message)
					push_warning(message)
					return
				
				# Generate random 2D coordinates in the range of min max
				var x = generate_random(min_x, max_x)
				var y = generate_random(min_y, max_y)
					
				# Generate random rotation
				var _rotation = Vector3()
				if scatterData["RandomRotation"]:
					var max_rotation = scatterData["MaxRotation"]
					_rotation.x = generate_random(0, max_rotation.x)
					_rotation.y = generate_random(0, max_rotation.y)
					_rotation.z = generate_random(0, max_rotation.z)
					
				# Generate random scale
				var _scale = Vector3(1.0, 1.0, 1.0)
				if scatterData["RandomScale"]:
					var max_scale = scatterData["MaxScale"]
					_scale.x = generate_random(1.0, max_scale.x)
					_scale.y = generate_random(1.0, max_scale.y)
					_scale.z = generate_random(1.0, max_scale.z)
						
				# Check if the 2D coordinates are inside the polygon.
				var pos : Vector2 = Vector2(x ,y)
			
				is_point_in_polygon = Geometry2D.is_point_in_polygon(pos, polygon)
				if is_point_in_polygon:
					
					# it is inside the polygon. But also check if it is inside an
					# exclude area. If it is in the exclude area, it is NOT
					# considered to be inside the polygon.
					
					# If the MultiScatterItem has defined a list of Exclude areas:
					# only consider these Exclude areas
					# otherwise consider all Exclude areas.
					var excludeArray
					if scatter_item.exclude.size() == 0:
						excludeArray = excludes
					else:
						excludeArray = scatter_item.exclude
						
					# Now go throuh the available exclude areas and check if
					# the generated coordinates are inside or not.
					for ex in excludeArray:
						if ex == null:
							var message = "The MultiScatterItem %s contains " \
								+"at least one empty exclude element. Please remove it or "\
								+"assign a valid MultiScatterExclude."
							push_error(message  % scatter_item.get_name())
							return
						if is_point_in_polygon: # only check if point still is regarded as in polygon
							var multiScatterExclude : MultiScatterExclude = ex
							var global_pos = pos + Vector2(global_position.x, global_position.z)
							is_point_in_polygon = not multiScatterExclude.is_point_in_polygon(global_pos)

					# Check again: Still in polygon?
					if is_point_in_polygon:
						# Yes. It is inside the polygon and in no exclude area.
						# Place the item.
						var pos_3D = Vector3(pos.x, 0, pos.y)
							
						is_point_in_polygon = place_item(
								scatter_item, 
								index,
								pos_3D, 
								avg_height, 
								global_position, 
								_rotation, 
								_scale, 
								_min_offset_y,
								_max_offset_y,
								_coll_mask, 
								space,
								additionalScene,
								targetNode)
		_debug("MultiMesh instances have been set.")
	else:
		print("You need to set up a polygon with at least 3 points.")

# Helper function to create a transform for the MultiMesh instance.
func create_transform(pos : Vector3, rotation : Vector3, scale : Vector3):
	var transform = Transform3D(Basis(), Vector3())\
		.rotated(Vector3.RIGHT, rotation.x)\
		.rotated(Vector3.FORWARD, rotation.y)\
		.rotated(Vector3.UP, rotation.z)\
		.scaled(scale)\
		.translated(pos)
	return transform

# Interface function to place the item.
# Needs to be overwritten by specific PlacementMode.
func place_item (
		scatter_item,
		index : int, 
		pos_3D : Vector3, 
		avg_height, 
		global_position, 
		rotation, 
		scale,
		min_offset_y,
		max_offset_y,
		collision_mask, 
		space,
		additionalScene,
		targetNode) -> bool:
	return false

# Clear the node where the additional scenes shall be dropped.
# (targetNode). Will be called for each "Generate"-Run.
func _clear_target_node(targetNode):
	if targetNode != null:
		_debug("Clear targetNode")
		for child in targetNode.get_children():
			targetNode.remove_child(child)
			child.queue_free()
	

# Places the additional scene underneath as child of the targetNode.
# at specific position (transform).
# Transform is supposed to be the position of the multiMesh object so that
# the additional scene appears at the same location.
func _place_additional_scene(additionalScene, targetNode, transform):
	
	if (additionalScene != null and targetNode != null):
		_debug("Placing Additional Scene")
		targetNode.transform = _multiScatter.global_transform
		var instance = additionalScene.instantiate()
		instance.transform  = transform
		
		targetNode.add_child(instance)
		var root = _multiScatter.get_tree().get_edited_scene_root()
		instance.set_owner(root)
		instance.set_name(targetNode.get_name())
	else:
		_debug("Not placing Additional Scene. No targetNode and/or additionalScene is set.")
