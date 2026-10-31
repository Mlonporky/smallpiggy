extends Node2D
## Composite before applying memory haze, so overlapping limbs remain opaque.
const Rig := preload("res://scenes/cabbage_act2/acorn_memory_rig.gd")
var rig: Node2D
var sprite: Sprite2D
var surface: SubViewport
var pose := 0

func _ready() -> void:
 surface = SubViewport.new()
 surface.size = Vector2i(512,512)
 surface.transparent_bg = true
 surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 surface.gui_disable_input = true
 add_child(surface)
 rig = Rig.new()
 rig.position = Vector2(210,390)
 rig.scale = Vector2.ONE*1.6
 surface.add_child(rig)
 sprite = Sprite2D.new()
 sprite.texture = surface.get_texture()
 sprite.centered = false
 sprite.position = -Vector2(210,390)/1.6
 sprite.scale = Vector2.ONE/1.6
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var soft := ShaderMaterial.new()
 soft.shader = preload("res://scenes/cabbage_act2/acorn_memory_pig.gdshader")
 soft.set_shader_parameter("blur",0.0022)
 soft.set_shader_parameter("clarity_alpha",0.88)
 sprite.material = soft
 add_child(sprite)

func hand_point() -> Vector2:
 return position+rig.hand_position("Arm_A")*scale

func other_hand_point() -> Vector2:
 return position+rig.hand_position("Arm_B")*scale

func collar_point() -> Vector2:
 return position+rig.collar_point()*scale

func walk(distance: float) -> void:
 rig.travel += distance/scale.x
