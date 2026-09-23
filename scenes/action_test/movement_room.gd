extends Node2D
const Player = preload("res://scenes/action_test/player.tscn")
const Follow = preload("res://scenes/action_test/components/follow_camera.gd")
const Terrain = preload("res://scenes/chapter2/underground/terrain_art.gd")
const BG = preload("res://assets/chapter2/underground/root_grotto_v1.png")
const PLATFORMS := [Rect2(0,900,1000,500),Rect2(1130,900,950,500),Rect2(2230,900,2570,500),Rect2(660,840,140,60),Rect2(900,750,160,24),Rect2(1170,660,160,24),Rect2(1450,570,210,24)]
var world: Node2D
var player: CharacterBody2D
var camera: Camera2D
var stage: Control
var hud: Label
var debug_label: Label
var paused := false
var terrain_layer: Node2D
var pause_notice: Label
var particles: Array[Dictionary] = []
var platforms: Array = []
func _ready() -> void:
 build_stage()
 platforms = room_platforms()
 build_platforms()
 terrain_layer = Node2D.new()
 world.add_child(terrain_layer)
 terrain_layer.draw.connect(func():
  for rect in platforms: Terrain.paint(terrain_layer,rect))
 spawn_player(Vector2(160,900))
 hud.text = "移动试验室  ·  A/D 移动  空格短/长跳  Esc暂停  R重来  F3调试"
func room_platforms() -> Array:
 return PLATFORMS.duplicate()

func build_stage() -> void:
 stage = Control.new()
 stage.size = Vector2(1536,864)
 stage.clip_contents = true
 add_child(stage)
 var container := SubViewportContainer.new()
 container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 container.scale = Vector2.ONE*3
 container.size = Vector2(512,288)
 stage.add_child(container)
 var viewport := SubViewport.new()
 viewport.size = Vector2i(512,288)
 viewport.world_2d = World2D.new()
 container.add_child(viewport)
 world = Node2D.new()
 viewport.add_child(world)
 world.draw.connect(draw_world)
 camera = Follow.new()
 world.add_child(camera)
 var backing := ColorRect.new()
 backing.position = Vector2(25,22)
 backing.size = Vector2(1486,85)
 backing.color = Color(0.03,0.08,0.06,0.88)
 backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(backing)
 hud = label("",Vector2(44,35),23)
 debug_label = label("",Vector2(44,125),21)
 debug_label.visible = false
 pause_notice = label("已暂停 · Esc继续",Vector2(620,380),30)
 pause_notice.visible = false
func label(value: String, at: Vector2, font_size: int) -> Label:
 var node := Label.new()
 node.position = at
 node.text = value
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("f2e4bf"))
 node.add_theme_color_override("font_shadow_color",Color.BLACK)
 node.add_theme_constant_override("shadow_offset_x",2)
 node.add_theme_constant_override("shadow_offset_y",2)
 stage.add_child(node)
 return node
func build_platforms() -> void:
 for rect in platforms: solid(rect)
 solid(Rect2(-60,0,60,1600))
 solid(Rect2(4800,0,60,1600))
 # Safe catch floor beneath gaps; steps make the fall recoverable.
 for rect in [Rect2(930,1120,1380,280),Rect2(1050,1030,110,24),Rect2(2070,1030,130,24)]:
  platforms.append(rect)
  solid(rect)
func solid(rect: Rect2) -> void:
 var body := StaticBody2D.new()
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = rect.size
 shape.shape = box
 body.position = rect.get_center()
 body.add_child(shape)
 world.add_child(body)
func spawn_player(at: Vector2) -> void:
 player = Player.instantiate()
 player.position = at
 world.add_child(player)
 player.movement_fx.connect(burst)
 camera.target = player
 camera.snap_to_target()
func burst(kind: String, at: Vector2, amount: float) -> void:
 for i in (3 if kind=="run" else 8):
  particles.append({"pos":at,"vel":Vector2(randf_range(-70,70),randf_range(-70,-15))*amount,"life":0.35,"color":Color("b9bd8d")})
func step_fx(delta: float) -> void:
 for i in range(particles.size()-1,-1,-1):
  particles[i].life -= delta
  particles[i].pos += particles[i].vel*delta
  if particles[i].life<=0: particles.remove_at(i)
func _physics_process(delta: float) -> void:
 layout()
 if paused: return
 step_fx(delta)
 camera.follow(delta)
 if player.position.y>1350: player.reset_at(Vector2(160,900))
 debug_label.text = "State %s\nVelocity %s\nGrounded %s\nCoyote %.2f  Buffer %.2f" % ["GROUND" if player.is_on_floor() else "AIR",player.velocity,player.is_on_floor(),player.grace,player.buffer]
 world.queue_redraw()
func layout() -> void:
 var size := get_viewport_rect().size
 stage.scale = Vector2.ONE*minf(size.x/1536,size.y/864)
 stage.position = (size-stage.size*stage.scale)*0.5
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.is_pressed() or event.is_echo(): return
 if event.keycode==KEY_ESCAPE:
  paused = not paused
  player.paused = paused
  pause_notice.visible = paused
 elif event.keycode==KEY_R: get_tree().reload_current_scene()
 elif event.keycode==KEY_F3: debug_label.visible = not debug_label.visible
func draw_world() -> void:
 for i in 4: world.draw_texture_rect(BG,Rect2(i*2304-(camera.position.x-768)*0.3,0,2304,1296),false)
 for dust in particles: world.draw_rect(Rect2(dust.pos,Vector2(4,4)),Color(dust.color,clampf(dust.life/0.35,0,1)))
