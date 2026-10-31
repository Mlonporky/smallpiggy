extends Node2D
## Deterministic 1.4-second return to cabbage form when he remembers her.
## The original boy sprite and connected cabbage rig stay at fixed dimensions.
const DURATION := 1.4
const SHADER := preload("res://scenes/finale/transformation.gdshader")
var actor: Node2D
var boy_material: ShaderMaterial
var cabbage_material: ShaderMaterial
var painted: Array[CanvasItem] = []
var progress := 0.0
var seconds := 0.0

func setup(target: Node2D) -> void:
 actor = target
 boy_material = ShaderMaterial.new()
 boy_material.shader = SHADER
 boy_material.set_shader_parameter("appearing", false)
 cabbage_material = ShaderMaterial.new()
 cabbage_material.shader = SHADER
 actor.sprite.material = boy_material
 actor.sprite.visible = true
 _apply_to_painted(actor.rig)
 z_index = 5
 sample(0)

func _apply_to_painted(node: Node) -> void:
 if node is Sprite2D or node is Polygon2D:
  painted.append(node)
  node.material = cabbage_material
 for child in node.get_children(): _apply_to_painted(child)

func sample(time: float) -> void:
 seconds = clampf(time, 0, DURATION)
 progress = smoothstep(0.12, 1.32, seconds)
 var origin: Vector2 = actor.to_global(Vector2(0, -actor.height * .28))
 for material in [boy_material, cabbage_material]:
  material.set_shader_parameter("heart_origin", origin)
  material.set_shader_parameter("visible_height", actor.height * actor.global_scale.y)
  material.set_shader_parameter("progress", progress)
 actor.sprite.visible = progress < 1.0
 queue_redraw()

func finish() -> void:
 actor.sprite.material = null
 actor.sprite.visible = actor.rig == null
 for item in painted:
  if is_instance_valid(item): item.material = null

func _draw() -> void:
 # Small motes follow the wave, never a white flash over the whole frame.
 var envelope := sin(progress * PI)
 if envelope <= 0: return
 var center := Vector2(0, -actor.height * .28)
 for i in 14:
  var angle := i * TAU / 14.0 + .16 * seconds
  var radius: float = actor.height * (.08 + progress * .52)
  var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
  point.y -= 4 * sin(progress * PI)
  draw_circle(point, 1.0 + .5 * sin(i * 2.4), Color(.99, .88, .53, envelope * .55), true, -1, true)
