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
extends EditorPlugin

var MultiScatter = preload("MultiScatter.gd")
var MultiScatterItem = preload("MultiScatterItem.gd")
var MultiScatterExclude = preload("MultiScatterExclude.gd")

var _selected_scatter : MultiScatter
var _gui_toolbar = null

func _enter_tree():
	# Add thre custom types.
	add_custom_type("MultiScatter", "Path3D", MultiScatter, preload("icon.png"))
	add_custom_type("MultiScatterItem", "MultiMeshInstance3D", MultiScatterItem, preload("iconScatterItem.png"))
	add_custom_type("MultiScatterExclude", "Path3D", MultiScatterExclude, preload("iconExclude.png"))
	
	# Set up the toolbar and hide it. (Toolbar = the generate button)
	_gui_toolbar = load("res://addons/yamms/MultiScatter_Toolbar.tscn").instantiate()
	_gui_toolbar.visible = false
	
	# Add the toolbar to the Editor view.
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _gui_toolbar)
	_gui_toolbar.generate_button.pressed.connect(_on_generate_button_pressed)




func _exit_tree():
	remove_custom_type("MultiScatter")
	remove_custom_type("MultiScatterItem")
	_gui_toolbar.visible = false
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _gui_toolbar)
	_gui_toolbar.queue_free()


# Plugin GUI (Toolbar) is visible when Scatter is selected.	
func _handles(object) -> bool:
	if object is MultiScatter:
		_selected_scatter = object as MultiScatter
		return true
	else:
		_selected_scatter = null
		return false
		

func _make_visible(visible : bool):
	if not visible:
		_selected_scatter = null
		
	_gui_toolbar.visible = visible

# Toolbar generate button has been pressed. So: Generate	
func _on_generate_button_pressed():
	if _selected_scatter != null:
		_selected_scatter.do_generate()
