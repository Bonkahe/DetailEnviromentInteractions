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
extends PlacementMode
class_name PMDropOnFloor

	
func _debug(message):
	if _debug_messages:
		print("YAMMS: PMDropOnFloor:  " + message)
		
func place_item(
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
	# Distribute ScatterItems dropped on ground.
	# Do a raycast down
	pos_3D.y = avg_height
	
	var ray := PhysicsRayQueryParameters3D.create(
		pos_3D + global_position,
		pos_3D + global_position + Vector3.DOWN * 10000,
		collision_mask)

	var hit = space.intersect_ray(ray)
	
	# Did the raycast hit something?
	if hit.is_empty():
		# Raycast did not hit anything. Item cannot be placed.
		_debug("Raycast did not hit a collision object for index %s. Trying again." %index)
		return false
	else:
		# Raycast hit a collision object. Placing it there.
		var hit_pos = hit["position"]
		var multimesh_scatter_pos = global_position
		hit_pos = hit_pos - multimesh_scatter_pos
		_debug("Set position for index %s to %s" %[index, hit_pos])
		var transform = create_transform(hit_pos, rotation, scale)
		scatter_item.do_transform(index, transform)
		_place_additional_scene(additionalScene, targetNode, transform)
		return true
