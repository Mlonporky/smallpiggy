extends Node2D
## Reuse inspected atlas bounds, with feet aligned and fixed visible scale per actor.
const Art = preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
const BOY_WALK_CYCLE := [0,1,2,1]
var kind := "pig"
var height := 170.0
var facing := 1.0
var distance := 0.0
var sprite: Sprite2D
var bounds: Array[Rect2] = []
var sheet: Texture2D
var rig: Node2D
var prepared_rigs: Dictionary = {}
var walking := false
var move_blend := 0.0
var frame := -1
var expression: Node2D
var transformation: Node2D
func _ready() -> void:
 sprite = Sprite2D.new()
 sprite.centered = false
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 add_child(sprite)
 var initial_kind := kind
 # Prepare the alternate form outside the cinematic transition; retain it for replay.
 if initial_kind == "boy": configure("cabbage")
 configure(initial_kind)
 expression = preload("res://scenes/finale/reunion_expression.gd").new()
 expression.actor = self
 expression.z_index = 6
 add_child(expression)
func configure(value: String) -> void:
 if transformation != null:
  transformation.finish()
  transformation.free()
  transformation = null
 if rig != null:
  if kind == value: return
  rig.visible = false
  rig = null
 kind = value
 if kind in ["pig", "cabbage"]:
  if prepared_rigs.has(kind):
   rig = prepared_rigs[kind]
   rig.visible = true
   rig.contact_weight = 0.0
   sprite.visible = false
   pose(false)
   return
  rig = (preload("res://scenes/finale/finale_pig_rig.gd").new() if kind == "pig" else preload("res://scenes/finale/finale_cabbage_rig.gd").new())
  add_child(rig)
  prepared_rigs[kind] = rig
  # Measure the visible head/body top against the actual aligned feet.
  var body: Sprite2D = rig.artwork.Body if kind == "cabbage" else rig.core.get_node("Body")
  var top := rig.to_local(body.to_global(body.offset)).y
  var factor := height / -top
  rig.scale = Vector2.ONE * factor
  sprite.visible = false
  pose(false)
  return
 sprite.visible = true
 bounds = []
 frame = -1
 if kind == "pig":
  sheet = preload("res://assets/chapter2/pig_unified/cape.png")
  bounds = SpriteAtlas.bounds(sheet,4,4,[],0.10)
 elif kind == "boy":
  sheet = preload("res://assets/chapter1/boy.png")
  bounds = SpriteAtlas.bounds(sheet,3,4,PackedInt32Array([0,368,694,1028,1448]),0.10)
 elif kind == "cabbage":
  sheet = Art.CABBAGE
  bounds.assign(Art.CABBAGE_REGIONS)
 else:
  sheet = preload("res://assets/chapter2/wizard.png")
  bounds = SpriteAtlas.bounds(sheet,3,4,[],0.10)
 pose(false)
func begin_transformation() -> void:
 # Restore the same left-facing boy for direct entry, replay and save/resume.
 configure("boy")
 facing = -1
 pose(false)
 configure("cabbage")
 transformation = preload("res://scenes/finale/finale_transformation.gd").new()
 add_child(transformation)
 transformation.setup(self)

func sample_transformation(seconds: float) -> void:
 if transformation != null: transformation.sample(seconds)

func move_to_point(at: Vector2, delta: float, speed := 170.0) -> void:
 var old := position
 var remaining := position.distance_to(at)
 var approach_speed := minf(speed,remaining*6.0)
 position = position.move_toward(at,delta*approach_speed)
 if position.distance_to(at)<0.02: position=at
 var dx := position.x-old.x
 if absf(dx)>0.01: facing = signf(dx)
 var travelled := position.distance_to(old)
 distance += travelled
 var amount := clampf(travelled/maxf(delta*speed,0.001),0,1)
 move_blend=move_toward(move_blend,amount,delta*6.0)
 pose(move_blend>0.001,move_blend)
func pose(moving: bool, amount := 1.0) -> void:
 walking = moving
 if rig != null:
  rig.scale.x = absf(rig.scale.x) * (facing if kind == "pig" else -facing)
  rig.travel = distance / absf(rig.scale.x)
  rig.movement = amount if moving else 0.0
  rig.update_pose()
  queue_redraw()
  return
 var index := 0
 if kind == "pig": index = (12 if facing>0 else 4)+(int(distance/22)%4 if moving else 0)
 elif kind == "boy":
  # Authored rows: front, left, right, back. The last row is not right-facing.
  index = (6 if facing>0 else 3)+(BOY_WALK_CYCLE[int(distance/26)%4] if moving else 1)
 elif kind == "cabbage": index = int(distance/26)%4 if moving else 0
 index = mini(index,bounds.size()-1)
 if index!=frame:
  frame = index
  var rect := bounds[index]
  sprite.texture = SpriteAtlas.frame(sheet,rect)
  var reference: Rect2 = bounds[12 if kind=="pig" else (7 if kind=="boy" else 0)]
  var factor := height/reference.size.y
  sprite.scale = Vector2.ONE*factor
  sprite.position = Vector2(-rect.size.x/2,-rect.size.y)*factor
 sprite.flip_h = kind=="cabbage" and facing<0
 queue_redraw()
func hand_world() -> Vector2:
 return rig.to_global(rig.near_hand)

func shoulder_world() -> Vector2:
 return rig.to_global(rig.shoulder())

func aim_hand(world_target: Vector2, weight: float) -> void:
 rig.aim_hand(rig.to_local(world_target), weight)

func clear_hand() -> void:
 if rig == null: return
 rig.contact_weight = 0.0
 if kind=="pig": rig.guard_weight=0.0
 rig.update_pose()

func _draw() -> void:
 draw_set_transform(Vector2(0,2),0,Vector2(1,0.22))
 draw_circle(Vector2.ZERO,height*0.23,Color(0.015,0.035,0.03,0.22),true,-1,true)
 draw_set_transform(Vector2.ZERO)
