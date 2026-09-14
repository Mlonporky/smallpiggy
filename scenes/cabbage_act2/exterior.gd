extends Node2D
## Outdoor study: fixed illustrated views, foot-level collision, reversible travel.
@export_enum("villa", "path", "mushroom") var location := "villa"
static var pending_entry := ""
const ROOT := "res://scenes/cabbage_act2/"
const DATA := {
 "villa": {"image":"mainvilla.png", "size":Vector2(1672,941), "title":"白菜 · 第二幕｜主屋门前", "spawn":Vector2(1120,535),
  "floor":[Vector2(1030,490),Vector2(1200,490),Vector2(1160,580),Vector2(980,665),Vector2(1400,860),Vector2(1310,910),Vector2(1030,855),Vector2(640,710),Vector2(625,610),Vector2(930,560)],
  "exits":[["living",Vector2(1135,520),"E · 回主屋"],["path",Vector2(1260,835),"E · 右前方的小路 →"]]},
 "path": {"image":"garden_path_v1.png", "size":Vector2(1448,1086), "title":"白菜 · 第二幕｜通往蘑菇屋的小路", "spawn":Vector2(285,450),
  "floor":[Vector2(180,375),Vector2(350,380),Vector2(425,525),Vector2(650,650),Vector2(915,760),Vector2(1100,705),Vector2(1220,710),Vector2(1200,815),Vector2(1350,910),Vector2(1280,985),Vector2(1030,930),Vector2(650,825),Vector2(380,670),Vector2(225,535)],
  "exits":[["villa",Vector2(270,420),"E · 返回主屋"],["mushroom",Vector2(1145,755),"E · 蘑菇屋院子 →"]]},
 "mushroom": {"image":"mushroom_day_v1.png", "size":Vector2(1448,1086), "title":"白菜 · 第二幕｜呆呆猪的蘑菇屋", "spawn":Vector2(470,740),
  "floor":[Vector2(275,650),Vector2(610,650),Vector2(785,635),Vector2(965,635),Vector2(1000,705),Vector2(1210,780),Vector2(1200,865),Vector2(1090,990),Vector2(960,995),Vector2(900,890),Vector2(560,825),Vector2(300,760)],
  "exits":[["path",Vector2(365,700),"E · 返回花园小路"],["door",Vector2(865,675),"E · 蘑菇屋门口"]]}
}
var player: PiggyPlayer
var camera: Camera2D
var ui: ChapterPresentation
var busy := false
var floor_polygon: PackedVector2Array

func _ready() -> void:
 var data: Dictionary = DATA[location]
 GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
 var bg := Sprite2D.new()
 bg.texture = load("res://assets/cabbage_act2/" + data.image)
 bg.centered = false
 bg.scale = data.size / bg.texture.get_size()
 bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(bg)
 floor_polygon = PackedVector2Array(data.floor)
 var boundary := StaticBody2D.new()
 add_child(boundary)
 for i in floor_polygon.size():
  var shape := SegmentShape2D.new()
  shape.a = floor_polygon[i]
  shape.b = floor_polygon[(i+1)%floor_polygon.size()]
  var collider := CollisionShape2D.new()
  collider.shape = shape
  boundary.add_child(collider)
 player = preload("res://actors/shared/player.tscn").instantiate()
 player.handpainted_room = true
 player.sheet_override = preload("res://assets/chapter1/boy.png")
 player.sheet_row_edges = PackedInt32Array([0,368,694,1028,1448])
 player.visible_height = 105.0
 player.move_speed = 155.0
 player.position = data.spawn
 if pending_entry == "path" and location == "villa": player.position = Vector2(1150,795)
 if pending_entry == "mushroom" and location == "path": player.position = Vector2(1045,795)
 pending_entry = ""
 player.get_node("Camera2D").enabled = false
 add_child(player)
 player.reset_physics_interpolation()
 camera = Camera2D.new()
 camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
 camera.position = data.size * 0.5
 add_child(camera)
 ui = ChapterPresentation.new()
 add_child(ui)
 ui.room_name.text = data.title
 ui.prompt.text = "WASD / 方向键\n移动\n\n走近标记按 E\nF5 保存\nEsc 菜单"
 for item in data.exits:
  var label := Label.new()
  label.position = item[1] + Vector2(-95,30)
  label.text = item[2]
  label.add_theme_font_size_override("font_size",20)
  label.add_theme_color_override("font_color",Color("fff1cc"))
  label.add_theme_color_override("font_outline_color",Color("40382c"))
  label.add_theme_constant_override("outline_size",6)
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(label)
 get_viewport().size_changed.connect(_fit)
 _fit()

func _fit() -> void:
 var size: Vector2 = DATA[location].size
 var viewport_size := get_viewport().get_visible_rect().size
 camera.zoom = Vector2.ONE * minf(viewport_size.x/size.x,viewport_size.y/size.y)

func _unhandled_input(event: InputEvent) -> void:
 if busy or SceneRouter.is_busy(): return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  pause_menu()
 elif event.is_action_pressed("interact"):
  for item in DATA[location].exits:
   if player.position.distance_to(item[1]) < 100:
    get_viewport().set_input_as_handled()
    travel(item[0])
    return

func travel(target: String) -> void:
 if busy or SceneRouter.is_busy(): return
 if target == "door":
  ui.prompt.text = "已到蘑菇屋门口\n\n室内探索尚未制作\n可沿小路返回主屋"
  GameState.set_flag("cabbage_mushroom_reached")
  return
 busy = true
 player.set_input_enabled(false)
 pending_entry = location
 if target == "living":
  ChapterRoomLayout.pending_entry = {"room":"living","position":Vector2(710,875)}
  SceneRouter.change_scene("res://scenes/chapter1/living.tscn")
 else:
  SceneRouter.change_scene(ROOT + target + ".tscn")

func pause_menu() -> void:
 busy = true
 player.set_input_enabled(false)
 var choice := await ui.choose({"stay":"继续探索","save":"保存并回主菜单"})
 if choice == "save" and SaveManager.save_game(scene_file_path):
  SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")
  return
 if choice == "save": ui.prompt.text = "保存失败，请重试"
 await get_tree().process_frame
 busy = false
 player.set_input_enabled(true)
