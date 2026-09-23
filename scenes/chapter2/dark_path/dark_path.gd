extends Node2D
## Isolated story segment: no GameState mutations or automatic saves.
signal fall_completed
enum Phase { EMERGE, WALK, CRACK, FALL, END }
const BACKGROUND = preload("res://assets/chapter2/dark_path/forest_v1.png")
const ACTIONS = preload("res://assets/chapter2/dark_path/pig_actions_source_v1.png")
const GROUND := 1152.0
const PIT_X := 1870.0
const SPEED := 210.0
const FONT = preload("res://assets/fonts/game_font.tres")
# Inspected alpha bounds, not an assumed equal grid. Common scale preserves head size.
const REGIONS := [Rect2(50,90,400,370), Rect2(572,88,395,373), Rect2(1083,90,400,370),
 Rect2(58,578,395,375), Rect2(562,555,422,385), Rect2(1075,564,402,405)]
const ANCHORS := [Vector2(260,362), Vector2(232,364), Vector2(260,361),
 Vector2(252,367), Vector2(254,377), Vector2(248,397)]
var phase := Phase.EMERGE
var phase_time := 0.0
var elapsed := 0.0
var pig_position := Vector2(185, GROUND - 220)
var camera_position := Vector2(0, 390)
var travel := 0.0
var velocity := 0.0
var facing := 1.0
var paused := false
var world: Node2D
var stage: Control
var pig: Sprite2D
var light_material: ShaderMaterial
var curtain: ColorRect
var hint: Label
var title: Label
var ending: VBoxContainer
var pause_label: Label
var ground_fx: Node2D
var foreground: Polygon2D
var debris: Array[Polygon2D] = []
var frames: Array[AtlasTexture] = []
var fall_origin := Vector2.ZERO
var frame_index := 0
# The standalone legacy ending remains available for regression tests.
@export var continue_underground := true
var murmur: PanelContainer
var murmur_time := 0.0
var murmur_count := 0
const MURMUR_CYCLE := 3.1

func _ready() -> void:
 stage = Control.new()
 stage.size = Vector2(1536,1024)
 stage.clip_contents = true
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 world = Node2D.new()
 stage.add_child(world)
 var background := Sprite2D.new()
 background.texture = BACKGROUND
 background.centered = false
 background.scale = Vector2.ONE * 1.5625
 world.add_child(background)
 ground_fx = Node2D.new()
 world.add_child(ground_fx)
 ground_fx.draw.connect(_draw_ground)
 for rect in REGIONS:
  var atlas := AtlasTexture.new()
  atlas.atlas = ACTIONS
  atlas.region = rect
  atlas.filter_clip = true
  frames.append(atlas)
 pig = Sprite2D.new()
 pig.centered = false
 pig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 world.add_child(pig)
 # Real foreground occlusion at the near edge: uses the background's exact UVs.
 foreground = Polygon2D.new()
 foreground.polygon = PackedVector2Array([Vector2(PIT_X-175,GROUND+62),Vector2(PIT_X-96,GROUND+44),Vector2(PIT_X+25,GROUND+65),Vector2(PIT_X+164,GROUND+42),Vector2(PIT_X+205,GROUND+100),Vector2(PIT_X+205,GROUND+850),Vector2(PIT_X-200,GROUND+850)])
 foreground.texture = BACKGROUND
 var uv := PackedVector2Array()
 for p in foreground.polygon: uv.append(p / 1.5625)
 foreground.uv = uv
 foreground.visible = false
 world.add_child(foreground)
 var darkness := ColorRect.new()
 darkness.size = Vector2(1536,1024)
 darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
 light_material = ShaderMaterial.new()
 light_material.shader = preload("res://scenes/chapter2/dark_path/darkness.gdshader")
 darkness.material = light_material
 stage.add_child(darkness)
 curtain = ColorRect.new()
 curtain.size = Vector2(1536,1024)
 curtain.color = Color.BLACK
 curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(curtain)
 title = _label("黑暗小径", 36, Vector2(70,68))
 hint = _label("A / D 或 ← / → 移动    ·    Esc 暂停", 21, Vector2(70,952))
 hint.modulate = Color("b9b4a8")
 pause_label = _label("已暂停\nEsc 继续", 32, Vector2(660,430))
 pause_label.visible = false
 ending = VBoxContainer.new()
 ending.position = Vector2(568,440)
 ending.size = Vector2(400,200)
 ending.add_theme_constant_override("separation",22)
 stage.add_child(ending)
 var end_text := Label.new()
 end_text.text = "坠入黑暗"
 end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 end_text.add_theme_font_size_override("font_size",36)
 ending.add_child(end_text)
 var replay := Button.new()
 replay.text = "再走一次"
 replay.custom_minimum_size.y = 60
 replay.pressed.connect(restart)
 ending.add_child(replay)
 var note := Label.new()
 note.text = "本段结束 · 后续横版冒险待续"
 note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 note.add_theme_font_size_override("font_size",20)
 ending.add_child(note)
 ending.visible = false
 murmur = PanelContainer.new()
 murmur.mouse_filter = Control.MOUSE_FILTER_IGNORE
 murmur.size = Vector2(230,64)
 var paper := StyleBoxFlat.new()
 paper.bg_color = Color("efe4cd")
 paper.border_color = Color("bba681")
 paper.set_border_width_all(2)
 paper.set_corner_radius_all(14)
 paper.content_margin_left = 22
 paper.content_margin_right = 22
 paper.content_margin_top = 10
 paper.content_margin_bottom = 10
 murmur.add_theme_stylebox_override("panel",paper)
 stage.add_child(murmur)
 var words := Label.new()
 words.text = "我不害怕"
 words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 words.add_theme_font_override("font",FONT)
 words.add_theme_font_size_override("font_size",28)
 words.add_theme_color_override("font_color",Color("554939"))
 words.mouse_filter = Control.MOUSE_FILTER_IGNORE
 murmur.add_child(words)
 murmur.visible = false
 _layout()
 _update_visual()

func _label(text: String, size: int, at: Vector2) -> Label:
 var label := Label.new()
 label.text = text
 label.position = at
 label.add_theme_font_override("font",FONT)
 label.add_theme_font_size_override("font_size",size)
 stage.add_child(label)
 return label

func _layout() -> void:
 var viewport := get_viewport_rect().size
 var factor := minf(viewport.x / 1536.0, viewport.y / 1024.0)
 stage.scale = Vector2.ONE * factor
 stage.position = (viewport - Vector2(1536,1024) * factor) * 0.5

func _unhandled_key_input(event: InputEvent) -> void:
 if not event.is_pressed() or event.is_echo(): return
 if event is InputEventKey and event.keycode == KEY_ESCAPE and phase != Phase.END:
  paused = not paused
  pause_label.visible = paused
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.keycode == KEY_R and phase == Phase.END:
  restart()

func restart() -> void:
 get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
 _layout()
 if paused: return
 elapsed += delta
 phase_time += delta
 match phase:
  Phase.EMERGE:
   var old_position := pig_position
   pig_position.x = lerpf(185,400,smoothstep(0,1,phase_time / 2.6))
   pig_position.y = lerpf(GROUND-220,GROUND,smoothstep(0,1,phase_time / 2.6))
   travel += pig_position.distance_to(old_position)
   curtain.color.a = 1.0 - smoothstep(0,1,phase_time / 1.1)
   if phase_time >= 2.6: _set_phase(Phase.WALK)
  Phase.WALK:
   murmur_time += delta
   murmur_count = 1 + int(murmur_time / MURMUR_CYCLE)
   var direction := Input.get_axis("move_left","move_right")
   velocity = move_toward(velocity,direction*SPEED,delta*850)
   var old_x := pig_position.x
   pig_position.x = clampf(pig_position.x + velocity*delta,350,PIT_X)
   travel += absf(pig_position.x - old_x)
   if absf(velocity) > 3: facing = signf(velocity)
   if pig_position.x >= PIT_X - 8:
    velocity = 0
    facing = 1
    _set_phase(Phase.CRACK)
  Phase.CRACK:
   if phase_time > 0.48:
    fall_origin = pig_position
    _make_debris()
    foreground.visible = true
    _set_phase(Phase.FALL)
  Phase.FALL:
   pig_position = fall_origin + Vector2(24*sin(minf(phase_time,1.0)*PI/2),-36*phase_time+500*phase_time*phase_time)
   for i in debris.size():
    debris[i].position = Vector2(PIT_X-145+i*49,GROUND) + Vector2((i-2.5)*14*phase_time,(20+i*11)*phase_time+(290+i*27)*phase_time*phase_time)
    debris[i].rotation = sin(i*9.0)*phase_time*1.8
   curtain.color.a = smoothstep(1.05,2.15,phase_time)
   if phase_time >= 2.5:
    _set_phase(Phase.END)
    fall_completed.emit()
    if continue_underground:
     get_tree().call_deferred("change_scene_to_file","res://scenes/chapter2/underground/landing.tscn")
    else:
     ending.visible = true
     ending.get_child(1).grab_focus()
  Phase.END:
   curtain.color.a = 1
 _update_visual()

func _set_phase(next: Phase) -> void:
 phase = next
 phase_time = 0
 hint.visible = phase == Phase.WALK
 if phase != Phase.WALK: murmur.visible = false

func _update_visual() -> void:
 camera_position.x = lerpf(camera_position.x,clampf(pig_position.x-610,0,864),0.065)
 var shake := Vector2.ZERO
 if phase == Phase.CRACK: shake = Vector2(sin(phase_time*80)*3,sin(phase_time*65)*2)
 if phase == Phase.FALL: shake = Vector2(sin(phase_time*65),cos(phase_time*70))*4*maxf(0,1-phase_time)
 world.position = -camera_position + shake
 frame_index = [0,1,2,3][int(travel / 19.0) % 4]
 if phase == Phase.WALK and absf(velocity) < 3: frame_index = 1
 if phase == Phase.CRACK: frame_index = 4
 if phase in [Phase.FALL,Phase.END]: frame_index = 5
 pig.texture = frames[frame_index]
 pig.offset = -ANCHORS[frame_index]
 pig.position = pig_position
 pig.scale = Vector2(0.46*facing,0.46)
 pig.rotation = sin(phase_time*8)*0.03 if phase == Phase.CRACK else (minf(phase_time,1)*0.1 if phase == Phase.FALL else 0.0)
 if phase in [Phase.EMERGE,Phase.WALK] and (phase == Phase.EMERGE or absf(velocity)>3):
  pig.position.y -= 2.0 * absf(sin(travel / 76.0 * TAU))
 var light_pos := pig_position-camera_position+Vector2(0,-74)+shake
 light_material.set_shader_parameter("light_position",light_pos)
 light_material.set_shader_parameter("radius",245.0 + 5*sin(elapsed*2.2))
 light_material.set_shader_parameter("strength",1.0 if phase != Phase.FALL else 1.0-smoothstep(0.65,1.8,phase_time))
 title.modulate.a = 1.0-smoothstep(3.5,6.0,elapsed)
 var cycle := fmod(murmur_time,MURMUR_CYCLE)
 murmur.visible = phase == Phase.WALK and cycle < 2.4
 murmur.modulate.a = smoothstep(0,0.25,cycle)*(1-smoothstep(1.95,2.4,cycle))
 var bubble_at := pig_position-camera_position+Vector2(65,-235)
 murmur.position = Vector2(clampf(bubble_at.x,24,1282),clampf(bubble_at.y,100,880))
 ground_fx.queue_redraw()

func _draw_ground() -> void:
 # The only light source is her small warm aura, never a lamp in the scenery.
 for i in range(14,0,-1):
  ground_fx.draw_circle(pig_position+Vector2(0,-72),float(i)*7.0,Color(1.0,0.65,0.27,0.008))
 if phase in [Phase.EMERGE,Phase.WALK]:
  ground_fx.draw_set_transform(pig_position,0,Vector2(1,0.25))
  ground_fx.draw_circle(Vector2.ZERO,45,Color(0,0,0,0.24))
  ground_fx.draw_set_transform(Vector2.ZERO)
 if phase == Phase.CRACK:
  var amount := clampf(phase_time/0.38,0,1)
  for i in 7:
   var center := Vector2(PIT_X,GROUND+5)
   var tip := center + Vector2.from_angle(i*TAU/7)*Vector2(150,48)*amount
   ground_fx.draw_polyline(PackedVector2Array([center,center.lerp(tip,0.5)+Vector2(5,-7),tip]),Color("080a0e"),3,true)
 if phase in [Phase.FALL,Phase.END]:
  var hole := PackedVector2Array()
  for i in 24:
   var a := i*TAU/24
   hole.append(Vector2(PIT_X,GROUND+16)+Vector2(cos(a)*172,sin(a)*64)*(1+0.055*sin(i*9)))
  ground_fx.draw_colored_polygon(hole,Color("030407"))
  hole.append(hole[0])
  ground_fx.draw_polyline(hole,Color("211e1b"),7,true)

func _make_debris() -> void:
 for i in 6:
  var piece := Polygon2D.new()
  var x := PIT_X - 145 + i*49
  piece.position = Vector2(x,GROUND)
  var width := 28.0 + 10*sin(i*7.0)
  piece.polygon = PackedVector2Array([Vector2(-8,-15),Vector2(width*0.7,-23),Vector2(width,-5),Vector2(width*0.6,19),Vector2(0,11)])
  piece.texture = BACKGROUND
  var uv := PackedVector2Array()
  for p in piece.polygon: uv.append((p+piece.position)/1.5625)
  piece.uv = uv
  world.add_child(piece)
  world.move_child(piece,pig.get_index())
  debris.append(piece)
