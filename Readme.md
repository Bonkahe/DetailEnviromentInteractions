<!-- ABOUT THE PROJECT -->
# About The Project

[![Usage for Water][water-example]]()
[![Usage for Terrain][terrain-example]]()
[![Usage for Grass][grass-example]]()

A pretty simple details interaction system designed for Godot 4.3, made in a couple days, soooo I should probably have put more effort/thought into it lol.
Hopefully it will prove helpful to people hoping to add a little more interaction into their world, a couple notes though:
This works fine so long as you don't have billions of stamps lying around, I would actually recommend using particle systems instead of the somewhat hacky way I implemented the stamps, as you'll get a lot better performance. 
Also the terrain is deforming at a little bit of an unrealistic level of detail in the example, this terrain has way more polygons than most terrains, and without tesselation being available in Godot (still hoping someone tackles geometry shaders at some point) that's not likely to change soon, that being said I am experimenting with paralax mapping, and maybe some other ways with my own terrain, so I geuss goonies never say never.


<!-- GETTING STARTED -->
## Getting Started


### Installation

1. Add the addon folder "addons\DetailEnviromentInteractions" to the addon folder of your project.
2. Enable the plugin using "Project\ProjectSettings\Plugins" and click the check box next to the plugin "DetailEnviromentInteractions" to enable it.
3. To run the system you will need three global shader variables, they can be added in the window "Project\ProjectSettings\Globals\ShaderGlobals".
4. Add the following variables:
  * GrassDetailViewportTexture (type: sampler2D)
  * GrassDetailViewportTextureCornerPosition (type: vec3)
  * GrassDetailViewportTextureSize (type: float)
5. Once these are added, you can begin to implement the system, begin by added the 'DetailsRenderer' packed scene to your scene, this can be found at "res://addons/DetailEnviromentInteractions/PackedScenes/DetailsRenderer.tscn"
6. Next set the "Player Model" within that node to the desired player node.

The details system is now ready to use, you may tune it to your specific needs, see Usage for info on the various settings.


### Usage

There are a couple settings of note, I will go over each here and how to use them.

Player Camera:
Should always be culling layer 19, I use this layer to render the details, you can change it but you will need to change the detail renderer camera cull mask.

Details Renderer:
1. RenderSize: Render size is the region that the details renderer will be scanning, this can be scaled up to allow interactions to be seen from further distances, however be aware, unless they are very large, anything over 64 meters really doesn't have a lot of value.
2. RepositionRate: The rate at which it will update the position of the node, this can be a larger interval, but be aware larger intervals may result in visual popping.
3. SnapStep: The step at which to snap the renderer, this should always be intervals of 2, I found 2 works just fine for me, but there's a very slight performance cost to updating it's position so be aware of that with this and the reposition rate.
4. Size: This is the size of the actual image the detail system is producing in pixels, the larger the more detail you will have, however the performance and memory cost will raise as well, anything past 512x512 seemingly doesn't have a lot of visual improvement, if Godot recieves an update allowing tesselation this may change, or if you are rendering a particularly large render size.

Everything else on the details renderer should be left as default.

### Shader Usage:
this gets a little bit more complex, and will require a bit of shader knowledge, I'll break this up into stamps, visual shaders, and gdshaders.

#### Stamps:
A couple examples can be found in "res://addons/DetailEnviromentInteractions/Example/PackedScenes/", these start with the name "detail_effect_(the effect in question)", these are just my way of writing data to the details renderer, obviously using actual particle emitters would be more performant, but I simply made these simple packed scenes for testing.
Each stamp is essentially a decal, which the details renderer picks up, and positions on a texture, in easily retrievable format, so shaders can read that data, and deform themselves accordingly.
Each one implements a shader "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectStamp.gdshader" which renders the alpha to the given color for the detail renderer to pick up. There are a couple of things you will need to know for implementing your own.
1. The stamp shader should probably have render modes: "blend_add", "unshaded", "cull_disabled" and "depth_test_disabled", feel free to experiment, but I found this lets the renderer pick it up easiest.
2. The stamp should be rendered to a mesh (either a plane, or your own particle system), on layer 19, this allows the details renderer to target that layer specifically.

#### Visual Shaders:
Visual shaders can access the interaction detail renderer by using the node "Addons/BonkaheEffects/DetailEffectsSample", this will retrieve the texture rendered at the current location if it exists, the alpha of the color output is an optional fade out alpha, which can be used to modulate the effect.
This will also introduce a couple parameters to your shader:
* FadeEffectAtEdges: bool, controls the fall off mask at the edges, this is neccesary for a smooth transition at the edge of the details render area.
* EdgeFadeSmoothness: float, the distance inwards the mask is faded, be aware a larger number than the RenderSize will create undesireable results.

#### GDShaders:
To implement the shader you will need a couple things:
* add "#include 'res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc'" to  the top of your shader, to import the library.
* retrieve the current detail renderer data using the function: "SampleDetailEffectsLayer()"
  
Now to implement the "SampleDetailEffectsLayer" function you will need to pass into it the position in world space, for vertex this can be retrieved using this code:
'''NODE_POSITION_WORLD + VERTEX'''
For Fragment it can be retrieved using this:
'''(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz'''

So for fragment the final code would be this:
'''vec4 result = SampleDetailEffectsLayer((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);'''

Then you can deform your mesh however you please with that data.

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->
## Contact

Bonkahe - bonkahecommercial@Gmail.com

Project Link: [https://github.com/Bonkahe/DetailEnviromentInteractions](https://github.com/Bonkahe/DetailEnviromentInteractions)
Youtube Video Intro: [AddLater](AddLater)

<!-- MARKDOWN LINKS & IMAGES -->

[water-example]: ExampleWater.gif
[terrain-example]: ExampleTerrain.gif
[grass-example]: ExampleGrass.gif
