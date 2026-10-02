extends Control
signal phase_changed(phase_name: String)
signal acorns_released
signal reflection_started
signal finished
const Art := preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
const Actor := preload("res://scenes/cabbage_act2/acorn_memory_actor.gd")
const Table := preload("res://scenes/cabbage_act2/table_slide_puzzle.gd")
const DESIGN := Vector2(1536,864)
const HATCH := Rect2(425,174,650,402)
const PIG_LINE := "白白菜！橡子真的太可爱了！"
const CABBAGE_LINE := "猪对橡子是真爱呀！"
const REFLECTION := "那个白菜感觉很熟悉，好像是我。。。可是我旁边的粉嘟嘟的是谁呢。。。我怎么完全想不起来？"
var release_table := true
var preview_mode := false
var auto_advance := false
var auto_duration := 2.8
var phase := "waiting"
var phase_time := 0.0
var elapsed := 0.0
var stage: Control
var table_layer: Node2D
var trail_layer: Node2D
var reality: Node2D
var lid_left: Node2D
var lid_right: Node2D
var pig: Node2D
var cabbage: Node2D
var picked_acorn: Sprite2D
var curtain: ColorRect
var dialogue: DialogueUI
var acorns: Array[Dictionary] = []
var started := false
var walking := false
var settled := 0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 stage = Control.new()
 stage.size = DESIGN
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.clip_contents = true
 add_child(stage)
 if preview_mode: make_reality()
 make_table()
 make_trail()
 curtain = ColorRect.new()
 curtain.size = DESIGN
 curtain.color = Color(0.11,0.075,0.07,0)
 curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(curtain)
 dialogue = preload("res://systems/dialogue/dialogue_ui.tscn").instantiate()
 dialogue.layer = 36
 add_child(dialogue)
 get_viewport().size_changed.connect(layout)
 layout()
 call_deferred("play")

func layout() -> void:
 var viewport := get_viewport().get_visible_rect().size
 var factor := minf(viewport.x/DESIGN.x,viewport.y/DESIGN.y)
 stage.scale = Vector2.ONE*factor
 stage.position = (viewport-DESIGN*factor)*0.5
 # Keep text in viewport pixels: its readability does not depend on stage scale.
 if dialogue:
  dialogue.panel.position = Vector2(viewport.x*0.10,viewport.y-186)
  dialogue.panel.size = Vector2(viewport.x*0.80,164)
  dialogue.text_label.add_theme_font_size_override("font_size",22 if viewport.x >= 900 else 18)

func background(texture: Texture2D, parent: Node2D) -> Sprite2D:
 var node := Sprite2D.new()
 node.texture = texture
 node.centered = false
 node.scale = DESIGN/texture.get_size()
 parent.add_child(node)
 return node

func caption(text: String, parent: Node) -> Label:
 var node := Label.new()
 node.text = text
 node.position = Vector2(45,32)
 node.add_theme_font_size_override("font_size",25)
 node.add_theme_color_override("font_color",Color("fff0da"))
 node.add_theme_constant_override("outline_size",3)
 node.add_theme_color_override("font_outline_color",Color("6d5140"))
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func make_reality() -> void:
 reality = Node2D.new()
 stage.add_child(reality)
 var image := background(preload("res://assets/cabbage_act2/mushroom_interior_day_v1.png"),reality)
 var factor := DESIGN.y/image.texture.get_height()
 image.scale = Vector2.ONE*factor
 image.position.x = (DESIGN.x-image.texture.get_width()*factor)*0.5
 var boy := Sprite2D.new()
 var source := preload("res://assets/chapter1/boy.png")
 var bounds := SpriteAtlas.bounds(source,3,4,PackedInt32Array([0,368,694,1028,1448]),0.01)
 boy.texture = Art.atlas(source,bounds[1])
 boy.centered = false
 var size_factor := 175.0/bounds[1].size.y
 boy.scale = Vector2.ONE*size_factor
 boy.position = Vector2(790,680)-Vector2(bounds[1].size.x*size_factor*0.5,175)
 reality.add_child(boy)

func make_table() -> void:
 table_layer = Node2D.new()
 stage.add_child(table_layer)
 var wood := Table.WoodSurface.new()
 wood.size = DESIGN
 wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
 table_layer.add_child(wood)
 caption("蘑菇屋 · 桌面",table_layer)
 var cavity := Polygon2D.new()
 cavity.polygon = PackedVector2Array([HATCH.position,HATCH.position+Vector2(HATCH.size.x,0),HATCH.end,HATCH.position+Vector2(0,HATCH.size.y)])
 cavity.color = Color("3e291c")
 table_layer.add_child(cavity)
 var rim := Line2D.new()
 rim.points = cavity.polygon
 rim.closed = true
 rim.width = 12
 rim.default_color = Color("cfab75")
 rim.antialiased = true
 table_layer.add_child(rim)
 lid_left = Node2D.new()
 lid_left.position = HATCH.position
 table_layer.add_child(lid_left)
 lid_right = Node2D.new()
 lid_right.position = HATCH.position+Vector2(HATCH.size.x,0)
 table_layer.add_child(lid_right)
 var texture := Table.ART
 for side in 2:
  var node := Sprite2D.new()
  node.texture = Art.atlas(texture,Rect2(Vector2(side*texture.get_width()*0.5,0),Vector2(texture.get_width()*0.5,texture.get_height())))
  node.centered = false
  node.scale = Vector2(HATCH.size.x*0.5,HATCH.size.y)/node.texture.get_size()
  if side == 1: node.position.x = -HATCH.size.x*0.5
  (lid_left if side == 0 else lid_right).add_child(node)

func make_trail() -> void:
 trail_layer = Node2D.new()
 trail_layer.visible = false
 stage.add_child(trail_layer)
 background(preload("res://assets/cabbage_act2/acorn_memory/trail_v1.png"),trail_layer)
 caption("回忆",trail_layer)
 cabbage = Actor.new()
 cabbage.visible_height = 175
 cabbage.position = Vector2(495,618)
 trail_layer.add_child(cabbage)
 pig = Actor.new()
 pig.is_pig = true
 pig.visible_height = 190
 pig.position = Vector2(680,622)
 trail_layer.add_child(pig)
 picked_acorn = Sprite2D.new()
 picked_acorn.texture = Art.acorn()
 picked_acorn.scale = Vector2.ONE*(25.0/Art.ACORN_REGION.size.y)
 picked_acorn.position = Vector2(1086,612)
 picked_acorn.rotation = 0.30
 picked_acorn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 trail_layer.add_child(picked_acorn)

func set_phase(value: String) -> void:
 phase = value
 phase_time = 0
 phase_changed.emit(value)

func fade(alpha: float, duration: float) -> void:
 var tween := create_tween()
 tween.tween_property(curtain,"color:a",alpha,duration)
 await tween.finished

func play() -> void:
 if started: return
 started = true
 if release_table:
  set_phase("table_closed")
  await get_tree().create_timer(0.45).timeout
  set_phase("table_opening")
  var opening := create_tween().set_parallel(true)
  opening.tween_property(lid_left,"scale:x",0.14,0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  opening.tween_property(lid_right,"scale:x",0.14,0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  await opening.finished
  # Bring falling nuts in front only after the two hinged panels have opened.
  spawn_acorns()
  set_phase("acorn_spill")
  acorns_released.emit()
  await get_tree().create_timer(3.4).timeout
 set_phase("enter_memory")
 await fade(1.0,0.55)
 table_layer.visible = false
 trail_layer.visible = true
 await fade(0.0,0.55)
 set_phase("trail_walk")
 walking = true
 await get_tree().create_timer(3.25).timeout
 walking = false
 pig.rotation = 0
 cabbage.rotation = 0
 # The ground acorn is reached, touched, then raised toward the front hoof.
 set_phase("pickup_reach")
 pig.set_pose(4,true)
 await get_tree().create_timer(0.55).timeout
 set_phase("pickup_lift")
 var lift := create_tween().set_parallel(true)
 lift.tween_property(picked_acorn,"position",pig.position+Vector2(65,-95),0.5).set_trans(Tween.TRANS_SINE)
 lift.tween_property(picked_acorn,"rotation",-0.1,0.5)
 await lift.finished
 pig.set_pose(5,true)
 await get_tree().create_timer(0.16).timeout
 picked_acorn.visible = false
 set_phase("pig_dialogue")
 await dialogue.say("粉嘟嘟的身影",PIG_LINE,0,0,auto_advance,auto_duration)
 set_phase("necklace_threading")
 pig.set_pose(6,true)
 var motion := create_tween()
 motion.tween_property(pig,"rotation",-0.035,0.4).set_trans(Tween.TRANS_SINE)
 motion.tween_property(pig,"rotation",0.02,0.45).set_trans(Tween.TRANS_SINE)
 motion.tween_property(pig,"rotation",0.0,0.4).set_trans(Tween.TRANS_SINE)
 await motion.finished
 pig.set_pose(7,true)
 set_phase("necklace_worn")
 await get_tree().create_timer(0.8).timeout
 set_phase("cabbage_dialogue")
 await dialogue.say("白白菜",CABBAGE_LINE,0,0,auto_advance,auto_duration)
 set_phase("return_reality")
 await fade(1.0,0.65)
 trail_layer.visible = false
 if preview_mode:
  reality.visible = true
  await fade(0.0,0.65)
 else:
  # A full-screen fade reveals the actual room and actual boy at his old position.
  var screen := ColorRect.new()
  screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  screen.color = curtain.color
  screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(screen)
  stage.visible = false
  var restore := create_tween()
  restore.tween_property(screen,"color:a",0.0,0.65)
  await restore.finished
  screen.queue_free()
 set_phase("reflection")
 reflection_started.emit()
 await dialogue.say("白白菜",REFLECTION,0,0,auto_advance,auto_duration)
 set_phase("finished")
 finished.emit()

func spawn_acorns() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 20261001
 for i in 28:
  var node := Sprite2D.new()
  node.texture = Art.acorn()
  var height := rng.randf_range(44,64)
  node.scale = Vector2.ONE*(height/Art.ACORN_REGION.size.y)
  node.position = Vector2(rng.randf_range(580,900),rng.randf_range(300,410))
  node.rotation = rng.randf_range(-0.35,0.35)
  node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  node.visible = false
  table_layer.add_child(node)
  acorns.append({"node":node,"velocity":Vector2(rng.randf_range(-100,100),rng.randf_range(-100,-20)),"floor":rng.randf_range(700,794),"delay":i*0.025,"spin":rng.randf_range(-2.5,2.5),"bounces":0,"settled":false})

func _process(delta: float) -> void:
 elapsed += delta
 phase_time += delta
 if walking:
  var travel := 100.0*delta
  pig.position.x += travel
  cabbage.position.x += travel
  pig.walk(travel)
  cabbage.walk(travel)
 if phase == "acorn_spill":
  for item in acorns:
   if phase_time < item.delay or item.settled: continue
   var node: Sprite2D = item.node
   node.visible = true
   var velocity: Vector2 = item.velocity
   velocity.y += 980*delta
   node.position += velocity*delta
   node.rotation += item.spin*delta
   if node.position.y > item.floor:
    node.position.y = item.floor
    item.bounces += 1
    if item.bounces >= 3 or absf(velocity.y)<80:
     item.settled = true
     settled += 1
     velocity = Vector2.ZERO
    else:
     velocity.y = -absf(velocity.y)*0.33
     velocity.x *= 0.62
     item.spin *= 0.50
   item.velocity = velocity

func _input(event: InputEvent) -> void:
 # Do not let Esc open the room menu or cancel a half-played memory.
 if phase != "finished" and event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
