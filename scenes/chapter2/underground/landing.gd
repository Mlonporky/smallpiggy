extends Node2D
## Isolated first-room study. No inventory, save, or main-story state changes.
const BACKDROP = preload("res://assets/chapter2/underground/root_grotto_v1.png")
const TerrainArt = preload("res://scenes/chapter2/underground/terrain_art.gd")
const Combat = preload("res://scenes/chapter2/underground/combat.gd")
var combat: Node2D
const Pig = preload("res://scenes/chapter2/underground/pig.gd")
const SIZE := Vector2(1536,864)
const PLATFORMS := [Rect2(0,730,1536,150),Rect2(580,622,210,108),Rect2(885,526,205,24),Rect2(1200,440,220,24)]
var stage: Control
var world: Node2D
var pig: CharacterBody2D
var paused := false
var elapsed := 0.0
var curtain: ColorRect
var pause_label: Label
var hint: Label

func _ready() -> void:
 stage = Control.new()
 stage.size = SIZE
 stage.clip_contents = true
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 var container := SubViewportContainer.new()
 container.size = SIZE/3
 container.scale = Vector2.ONE*3
 container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 container.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(container)
 var viewport := SubViewport.new()
 viewport.size = Vector2i(SIZE/3)
 viewport.world_2d = World2D.new()
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 container.add_child(viewport)
 world = Node2D.new()
 viewport.add_child(world)
 var camera := Camera2D.new()
 camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
 camera.position = SIZE/2
 camera.zoom = Vector2.ONE/3
 world.add_child(camera)
 world.draw.connect(_draw_room)
 for rect in PLATFORMS: _solid(rect)
 _solid(Rect2(-60,-500,60,1500))
 _solid(Rect2(1536,-500,60,1500))
 pig = Pig.new()
 pig.position = Vector2(265,160)
 pig.velocity.y = 250
 world.add_child(pig)
 _plate(Rect2(42,32,455,118))
 _plate(Rect2(42,753,1452,93))
 _label("地下 · 苔根遗迹",Vector2(64,48),30)
 hint = _label("A / D 移动    空格 跳跃    J 攻击    E 武器架    Esc 暂停    R 重试",Vector2(64,810),21)
 pause_label = _label("已暂停 · Esc 继续",Vector2(610,340),32)
 pause_label.visible = false
 curtain = ColorRect.new()
 curtain.size = SIZE
 curtain.color = Color.BLACK
 curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(curtain)
 combat = Combat.new()
 world.add_child(combat)
 world.move_child(combat,pig.get_index())
 combat.setup(self)
 _layout()
 world.queue_redraw()

func _solid(rect: Rect2) -> void:
 var body := StaticBody2D.new()
 var collision := CollisionShape2D.new()
 var shape := RectangleShape2D.new()
 shape.size = rect.size
 collision.shape = shape
 body.position = rect.get_center()
 body.add_child(collision)
 world.add_child(body)

func _label(value: String, at: Vector2, size: int) -> Label:
 var label := Label.new()
 label.text = value
 label.position = at
 label.add_theme_font_size_override("font_size",size)
 label.modulate = Color("eee3c8")
 stage.add_child(label)
 return label

func _layout() -> void:
 var viewport := get_viewport_rect().size
 var factor := minf(viewport.x/SIZE.x,viewport.y/SIZE.y)
 stage.scale = Vector2.ONE*factor
 stage.position = (viewport-SIZE*factor)*0.5

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.is_pressed() or event.is_echo(): return
 if combat.handle_key(event.keycode):
  get_viewport().set_input_as_handled()
  return
 if event.keycode == KEY_ESCAPE:
  paused = not paused
  pig.paused = paused
  pause_label.visible = paused
  get_viewport().set_input_as_handled()
 elif event.keycode == KEY_R:
  get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
 _layout()
 if paused or combat.menu.visible: return
 combat.tick(delta)
 elapsed += delta
 curtain.color.a = 1-smoothstep(0,0.65,elapsed)
 hint.visible = pig.landed_once
 if pig.position.y > 1000: get_tree().reload_current_scene()
 world.queue_redraw()

func _plate(rect: Rect2) -> void:
 var panel := Panel.new()
 panel.position = rect.position
 panel.size = rect.size
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.04,0.09,0.07,0.87)
 style.border_color = Color("586547")
 style.set_border_width_all(1)
 panel.add_theme_stylebox_override("panel",style)
 stage.add_child(panel)

func _draw_room() -> void:
 world.draw_texture_rect(BACKDROP,Rect2(Vector2.ZERO,SIZE),false)
 # Quiet the artwork slightly, retaining separation from the solid foreground.
 world.draw_rect(Rect2(Vector2.ZERO,SIZE),Color(0.05,0.10,0.08,0.12))
 for rect in PLATFORMS: TerrainArt.paint(world,rect)
 for i in 16:
  var at := Vector2(80+i*91,230+fmod(i*139.0,440.0)+sin(elapsed*0.7+i)*7).snapped(Vector2(3,3))
  world.draw_rect(Rect2(at,Vector2(3,3)),Color(0.78,0.83,0.58,0.28))
 var strength := clampf(1-(730-pig.position.y)/180,0,1)
 world.draw_set_transform(Vector2(pig.position.x,733),0,Vector2(1,0.18))
 world.draw_circle(Vector2.ZERO,32,Color(0.02,0.05,0.03,strength*0.45))
 world.draw_set_transform(Vector2.ZERO)
