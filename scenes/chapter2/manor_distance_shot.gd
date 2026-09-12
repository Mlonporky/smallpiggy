extends Node2D
## A temporary camera reveal, not another explorable map or a replacement background.
signal fully_revealed
const FAR_CENTER := Vector2(724,-620)
const MANOR_LIGHT := Vector2(724,-1750)
const FAR_ZOOM := 0.35
var progress := 0.0
var camera: Camera2D
var original_center := Vector2.ZERO
var phase := 0.0
var plate_material: ShaderMaterial

func _ready() -> void:
	z_index = -5

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	# Almost no detail in the distance: the single warm point is the destination.
	draw_rect(Rect2(-20000,-20000,40000,40000),Color("020207"))
	var visibility := smoothstep(0.45,0.95,progress)
	var breath := 0.93 + sin(phase * 1.6) * 0.07
	for i in range(18,0,-1):
		var radius := float(i) * 3.5
		draw_circle(MANOR_LIGHT,radius,Color(1,0.66,0.28,0.010 * visibility * breath))
	draw_circle(MANOR_LIGHT,7,Color(1,0.77,0.40,0.8 * visibility))
	draw_circle(MANOR_LIGHT,3,Color(1,0.95,0.76,visibility))

func set_progress(value: float) -> void:
	progress = value
	apply_camera()
	plate_material.set_shader_parameter("reveal",progress)

func apply_camera() -> void:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x/1448.0,viewport_size.y/1086.0)
	camera.zoom = Vector2.ONE * fit * lerpf(1.0,FAR_ZOOM,progress)
	camera.position = original_center.lerp(FAR_CENTER,progress)

func play(scene: Node2D, background: Sprite2D) -> void:
	camera = scene.camera
	original_center = camera.position
	var old_offset := camera.offset
	var old_material := background.material
	var old_ui_visible: bool = scene.ui.visible
	var old_world_color: Color = scene.world.modulate
	camera.offset = Vector2.ZERO
	scene.ui.hide()
	# Fade only the map edges as the camera reveals the empty distance; preserve the PNG.
	plate_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float reveal : hint_range(0.0,1.0) = 0.0;
void fragment() {
	vec4 ink = texture(TEXTURE,UV);
	vec2 edge = min(UV,vec2(1.0)-UV);
	float mask = smoothstep(0.0,0.24,edge.x) * smoothstep(0.0,0.28,edge.y);
	ink.rgb *= mix(1.0,0.38,reveal);
	ink.a *= mix(1.0,mask,reveal);
	COLOR = ink;
}
"""
	plate_material.shader = shader
	background.material = plate_material
	# The distant darkness is behind the original painting and real characters.
	set_progress(0)
	var outward := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	outward.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	outward.tween_method(set_progress,0.0,1.0,3.2)
	outward.parallel().tween_property(scene.world,"modulate",Color(0.65,0.65,0.72,1),3.2)
	await outward.finished
	fully_revealed.emit()
	await get_tree().create_timer(2.2,false).timeout
	var inward := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	inward.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	inward.tween_method(set_progress,1.0,0.0,2.4)
	inward.parallel().tween_property(scene.world,"modulate",old_world_color,2.4)
	await inward.finished
	camera.position = original_center
	camera.offset = old_offset
	background.material = old_material
	scene.ui.visible = old_ui_visible
	scene.world.modulate = old_world_color
	queue_free()
