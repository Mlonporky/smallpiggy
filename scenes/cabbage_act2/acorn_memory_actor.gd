extends Node2D
const Art := preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
var is_pig := false
var visible_height := 190.0
var pose := -1
var sprite: Sprite2D
var previous: Sprite2D
var pose_tween: Tween
var gait_distance := 0.0
var breathing_time := 0.0

func _ready() -> void:
 previous = Sprite2D.new()
 sprite = Sprite2D.new()
 for node in [previous,sprite]:
  node.centered = false
  node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  add_child(node)
 if is_pig:
  var soft := ShaderMaterial.new()
  soft.shader = preload("res://scenes/cabbage_act2/acorn_memory_pig.gdshader")
  soft.set_shader_parameter("blur",0.0033)
  soft.set_shader_parameter("clarity_alpha",0.82)
  sprite.material = soft
  previous.material = soft
 set_pose(0)

func set_pose(index: int, blend := false) -> void:
 if index == pose: return
 if pose_tween and pose_tween.is_running(): pose_tween.kill()
 if blend and pose >= 0:
  previous.texture = sprite.texture
  previous.position = sprite.position
  previous.scale = sprite.scale
  previous.modulate.a = 1
 else: previous.modulate.a = 0
 pose = index
 var rect: Rect2 = Art.PIG_REGIONS[index] if is_pig else Art.CABBAGE_REGIONS[index]
 var feet: Vector2 = Art.PIG_FEET[index] if is_pig else Art.CABBAGE_FEET[index]
 var factor := visible_height/(365.0 if is_pig else 480.0)
 var source: Texture2D = Art.PIG if is_pig else Art.CABBAGE
 if is_pig and index == 4:
  rect = Art.PICKUP_REGION
  feet = Art.PICKUP_FEET
  source = Art.PICKUP
  factor = visible_height*0.84/rect.size.y
 sprite.texture = Art.atlas(source,rect)
 sprite.scale = Vector2.ONE*factor
 sprite.position = -(feet-rect.position)*factor
 sprite.modulate.a = 0 if blend else 1
 if blend:
  pose_tween = create_tween().set_parallel(true)
  pose_tween.tween_property(previous,"modulate:a",0.0,0.16)
  pose_tween.tween_property(sprite,"modulate:a",1.0,0.16)

func walk(distance: float) -> void:
 gait_distance += distance
 # Four sampled gait poses follow actual travel; pivot bob is continuous.
 set_pose(int(gait_distance/26.0)%4)
 rotation = 0.012*sin(TAU*gait_distance/104.0)

func _process(delta: float) -> void:
 breathing_time += delta
