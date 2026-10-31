extends Node2D
## One resumable cinematic with authored beats and two quiet playable approach paths.
## Preview uses a private state copy and never saves or mutates GameState.
signal beat_changed(id: String)
signal presentation_ready
const Story = preload("res://scenes/finale/finale_story.gd")
const Handhold = preload("res://scenes/finale/handhold_motion.gd")
const Actor = preload("res://scenes/finale/finale_actor.gd")
const SIZE := Vector2(1536,864)
const HOME_PIG := Vector2(900,625.5)
const HOME_CABBAGE := HOME_PIG+Vector2(-85,17)
const SAVE_SCENE := "res://scenes/finale/final_chapter.tscn"
const FOREST := preload("res://assets/finale/reunion_forest_v1.png")
const MANOR := preload("res://assets/backgrounds/piggy_manor.png")
const PAIR := preload("res://assets/finale/holding_hands_v1.png")
const MEMORIES := {
 "house": preload("res://assets/cabbage_act2/mushroom_day_v1.png"),
 "together": PAIR,
 "gift": preload("res://assets/prologue/gift_wrapping_unified.png"),
 "trail": preload("res://assets/cabbage_act2/acorn_memory/trail_v1.png"),
 "cape": preload("res://assets/finale/cape_memory_v2.png"),
 "cups": preload("res://assets/chapter1/kitchen_cabbage_cup_edit.png")}
@export var preview := false
@export var auto_advance := false
var flags: Dictionary = {}
var hearts := 0
var mode := ""
var beat := -1
var beat_time := 0.0
var beat_read_time := 0.0
var elapsed := 0.0
var path_distance := 0.0
var path_exiting := false
var home_arriving := false
var paused := false
# Short previews hold their last frame until an explicit replay.
var finished := false
var stage: Control
var world: Node2D
var path_tiles: Node2D
var background: Sprite2D
var tint: ShaderMaterial
var pig: Node2D
var cabbage: Node2D
var wizard: Node2D
var residents: Node2D
var hand_contact := false
var hand_point := Vector2.ZERO
var fx: Node2D
var trail_memory: SubViewport
var memory: TextureRect
var previous_memory: TextureRect
var memory_from_alpha := 0.0
var memory_shade_from := 0.0
var memory_shade: ColorRect
var curtain: ColorRect
var dialogue: Panel
var speaker: Label
var words: Label
var hint: Label
var chapter_label: Label
var title: Label
var menu: Panel
var menu_note: Label
var credits: VBoxContainer
var save_error := false
var _pending_route := false
var audio: Node
var rendering_ready := false
var rendering_preparation: Dictionary = {}

func _ready() -> void:
 flags = GameState.flags.duplicate(true)
 hearts = GameState.heart_progress
 if preview:
  flags = {"cave_level_completed":true,"mushroom_house_completed":true,"mushroom_red_fiber_seen":true}
  hearts = 3
 _build()
 _layout()
 var saved := str(flags.get("finale_checkpoint",""))
 if not preview and saved == "credits" and bool(flags.get("ending_completed",false)):
  enter_beat(Story.index_of("credits"))
 elif not preview and Story.index_of(saved)>=0 and reunion_ready():
  enter_beat(Story.index_of(saved))
 elif preview or (has("cave_level_completed") and not has("finale_pig_path_done")):
  enter_path("pig_path")
 elif has("mushroom_house_completed") and not has("finale_cabbage_path_done"):
  enter_path("cabbage_path")
 elif reunion_ready():
  enter_path("reunion_walk")
 else:
  mode = "blocked"
  hint.text = "两条路还没有走到终点。"
  chapter_label.text = "最终章 · 尚未抵达"
  _show_menu()
 _prepare_presentation()

func _prepare_presentation() -> void:
 if DisplayServer.get_name()=="headless" or not RenderingServer.render_loop_enabled:
  rendering_ready=true
  presentation_ready.emit()
  return
 var cover:=CanvasLayer.new()
 cover.layer=90
 var black:=ColorRect.new()
 black.color=Color(0.035,0.027,0.055,1)
 black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cover.add_child(black)
 add_child(cover)
 audio.pause(true)
 var textures: Array[Texture2D]=[FOREST,MANOR]
 for texture in MEMORIES.values(): textures.append(texture)
 rendering_preparation=await preload("res://scenes/finale/render_warmup.gd").prepare(self,textures)
 # The next process delta includes the expensive preparation draw. Keep the
 # story/audio frozen through that frame instead of jumping ahead on reveal.
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 cover.queue_free()
 rendering_ready=true
 audio.pause(paused or finished)
 presentation_ready.emit()

func wait_for_presentation() -> void:
 if not rendering_ready: await presentation_ready

func has(key: String) -> bool:
 return bool(flags.get(key,false))
func reunion_ready() -> bool:
 return has("cave_level_completed") and has("mushroom_house_completed") and has("finale_pig_path_done") and has("finale_cabbage_path_done")
func mark(key: String) -> void:
 flags[key] = true
 if not preview: GameState.set_flag(key)
func checkpoint(id: String) -> bool:
 if preview: return true
 GameState.flags["finale_checkpoint"] = id
 GameState.story_phase = GameState.StoryPhase.COMPLETED if has("ending_completed") else GameState.StoryPhase.FINALE
 save_error = not SaveManager.save_game(SAVE_SCENE)
 return not save_error

func _build() -> void:
 stage = Control.new()
 stage.size = SIZE
 stage.clip_contents = true
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 world = Node2D.new()
 # Keep the whole layered character world below memory cards and dialogue.
 world.z_index = -64
 stage.add_child(world)
 background = Sprite2D.new()
 background.centered = false
 background.texture = FOREST
 background.scale = SIZE/FOREST.get_size()
 background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 tint = ShaderMaterial.new()
 tint.shader = preload("res://scenes/finale/restoration.gdshader")
 background.material = tint
 world.add_child(background)
 path_tiles=Node2D.new()
 path_tiles.z_index=-1
 world.add_child(path_tiles)
 for i in 5:
  var tile:=Sprite2D.new()
  tile.texture=FOREST
  tile.centered=false
  tile.scale=SIZE/FOREST.get_size()
  tile.position.x=SIZE.x*i
  tile.flip_h=i%2==1
  tile.material=tint
  tile.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  path_tiles.add_child(tile)
 residents=preload("res://scenes/finale/manor_residents.gd").new()
 world.add_child(residents)
 for name_value in ["pig","boy","wizard"]:
  var actor: Node2D = preload("res://scenes/finale/finale_wizard.gd").new() if name_value=="wizard" else Actor.new()
  if name_value!="wizard": actor.kind = name_value
  actor.height = 180 if name_value == "wizard" else 165
  world.add_child(actor)
  if name_value=="pig": pig=actor
  elif name_value=="boy": cabbage=actor
  else: wizard=actor
 fx = Node2D.new()
 fx.z_index = 56
 world.add_child(fx)
 fx.draw.connect(_draw_fx)
 trail_memory=preload("res://scenes/finale/trail_memory.gd").new()
 add_child(trail_memory)
 memory_shade = _rect(Color(0.025,0.035,0.05,0.76),Vector2.ZERO,SIZE)
 memory = TextureRect.new()
 memory.position = Vector2(260,82)
 memory.size = Vector2(1016,590)
 memory.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 memory.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 memory.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(memory)
 previous_memory=memory.duplicate()
 stage.add_child(previous_memory)
 stage.move_child(previous_memory,memory.get_index())
 previous_memory.visible=false
 dialogue = _panel(Vector2(240,687),Vector2(1056,145))
 speaker = _label("",Vector2(270,705),24,Vector2(980,34))
 speaker.modulate = Color("eed6a5")
 words = _label("",Vector2(270,746),29,Vector2(986,68))
 words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 chapter_label = _label("",Vector2(45,28),19,Vector2(1100,32))
 chapter_label.modulate = Color(0.94,0.92,0.85,0.7)
 hint = _label("",Vector2(40,838),16,Vector2(1456,24))
 hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 curtain = _rect(Color(0,0,0,0),Vector2.ZERO,SIZE)
 title = _label("",Vector2(0,320),52,SIZE)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 credits = VBoxContainer.new()
 credits.position = Vector2(330,195)
 credits.size = Vector2(876,500)
 credits.add_theme_constant_override("separation",24)
 stage.add_child(credits)
 for line in ["猪猪山庄","—— 被遗忘的快乐 ——","故事与角色 · 猪猪山庄","制作工具 · Godot / Codex","部分美术 · AI 辅助生成与项目原稿","谢谢你陪她走完这段回家的路。"]:
  var label := Label.new()
  label.text = line
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size",32 if line=="猪猪山庄" else 22)
  credits.add_child(label)
 _button(credits,"重看最终章（不改存档）",func(): get_tree().change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn"))
 _button(credits,"回到主菜单",func(): SceneRouter.change_scene("res://scenes/bootstrap/main.tscn"))
 menu = _panel(Vector2(470,200),Vector2(596,440))
 var list := VBoxContainer.new()
 list.position = Vector2(40,35)
 list.size = Vector2(516,370)
 list.add_theme_constant_override("separation",18)
 menu.add_child(list)
 menu_note = Label.new()
 menu_note.text = "已暂停"
 menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 menu_note.add_theme_font_size_override("font_size",26)
 list.add_child(menu_note)
 _button(list,"继续",func(): _resume())
 _button(list,"设置与操作",AppSettings.open_panel)
 _button(list,"自动对白 / 手动对白",func(): auto_advance=not auto_advance; _resume())
 _button(list,"保存并回主菜单" if not preview else "退出预览",_save_and_exit)
 menu.visible = false
 audio = preload("res://scenes/finale/finale_audio.gd").new()
 add_child(audio)

func _rect(color: Color, at: Vector2, extent: Vector2) -> ColorRect:
 var node := ColorRect.new()
 node.position=at
 node.size=extent
 node.color=color
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stage.add_child(node)
 return node
func _panel(at: Vector2, extent: Vector2) -> Panel:
 var panel := Panel.new()
 panel.position=at
 panel.size=extent
 var style := StyleBoxFlat.new()
 style.bg_color=Color(0.035,0.06,0.065,0.94)
 style.border_color=Color(0.75,0.65,0.44,0.5)
 style.set_border_width_all(1)
 style.set_corner_radius_all(14)
 panel.add_theme_stylebox_override("panel",style)
 stage.add_child(panel)
 return panel
func _label(value: String, at: Vector2, size_value: int, extent: Vector2) -> Label:
 var node := Label.new()
 node.text=value
 node.position=at
 node.size=extent
 node.add_theme_font_size_override("font_size",size_value)
 stage.add_child(node)
 return node
func _button(parent: Node, value: String, callback: Callable) -> void:
 var button := Button.new()
 button.text=value
 button.custom_minimum_size.y=44
 button.pressed.connect(callback)
 parent.add_child(button)
func _layout() -> void:
 var extent := get_viewport_rect().size
 var factor := minf(extent.x/SIZE.x,extent.y/SIZE.y)
 stage.scale=Vector2.ONE*factor
 stage.position=(extent-SIZE*factor)/2

func enter_path(value: String) -> void:
 mode=value
 beat=-1
 beat_time=0
 path_distance=0
 path_exiting=false
 _reset_visuals(false)
 background.visible=value=="reunion_walk"
 path_tiles.visible=value!="reunion_walk"
 pig.position=Vector2(280,615)
 cabbage.position=Vector2(280,615)
 cabbage.facing=1
 pig.visible=value!="cabbage_path"
 cabbage.visible=value=="cabbage_path"
 chapter_label.text="最后一段路 · "+("白白菜" if value=="cabbage_path" else "小呆猪")+(" · 独立预览" if preview else "")
 hint.text="A / D 或 ← / → · 沿小路向前走    Esc · 暂停    M · 静音"
 if value=="reunion_walk": chapter_label.text="森林深处"
 if not preview: checkpoint(value)
 audio.set_mood("path")
 audio.begin_scene(value)
 curtain.color.a=1.0
 _sort_actors()
 beat_changed.emit(value)

func _reset_visuals(at_manor: bool) -> void:
 residents.visible=at_manor
 residents.sample(12.0 if at_manor else 0.0)
 background.visible=true
 path_tiles.visible=false
 background.texture=MANOR if at_manor else FOREST
 background.scale=SIZE/background.texture.get_size()
 tint.set_shader_parameter("manor",at_manor)
 tint.set_shader_parameter("restoration_time",10.0 if at_manor else 0.0)
 tint.set_shader_parameter("warmth",1.0 if at_manor else 0.38)
 world.scale=Vector2.ONE
 world.position=Vector2.ZERO
 trail_memory.render_target_update_mode=SubViewport.UPDATE_DISABLED
 memory.visible=false
 previous_memory.visible=false
 memory_shade.visible=false
 hand_contact=false
 pig.rig.attention=0.0
 pig.rig.brush=0.0
 pig.expression.dust_time=-1.0
 cabbage.expression.tear=0.0
 pig.expression.queue_redraw()
 cabbage.expression.queue_redraw()
 pig.clear_hand()
 cabbage.clear_hand()
 wizard.visible=false
 pig.visible=true
 cabbage.visible=true
 pig.modulate=Color.WHITE
 cabbage.modulate=Color.WHITE
 wizard.modulate=Color.WHITE
 curtain.color.a=0
 title.text=""
 credits.visible=false
 dialogue.visible=false
 speaker.visible=false
 words.visible=false

func current_id() -> String:
 return Story.BEATS[beat][0] if beat>=0 else mode
func after(id: String) -> bool:
 return beat>=Story.index_of(id)
func between(first: String,last: String) -> bool:
 return beat>=Story.index_of(first) and beat<=Story.index_of(last)

func enter_beat(index: int) -> void:
 if index<0 or index>=Story.BEATS.size(): return
 # Carry the outgoing memory plate over the cut, including when returning to
 # the actors. The beat clock owns the dissolve, so pause/seek create no tweens.
 var old_texture: Texture2D=memory.texture if memory.visible else previous_memory.texture
 var old_alpha: float=memory.modulate.a if memory.visible else (previous_memory.modulate.a if previous_memory.visible else 0.0)
 var old_shade: float=memory_shade.modulate.a if memory_shade.visible else 0.0
 mode="cinematic"
 beat=index
 beat_time=0
 beat_read_time=0
 var data: Array = Story.BEATS[beat]
 var id: String=data[0]
 var at_manor := after("manor_restore")
 _reset_visuals(at_manor)
 previous_memory.texture=old_texture
 previous_memory.visible=old_texture!=null and old_alpha>0
 memory_from_alpha=old_alpha
 memory_shade_from=old_shade
 var restored := after("remember_you")
 cabbage.configure("cabbage" if restored and id!="remember_you" else "boy")
 cabbage.facing=-1
 pig.facing=1
 pig.pose(false)
 cabbage.pose(false)
 if id=="remember_you": cabbage.begin_transformation()
 pig.position=Vector2(630 if after("reunion_close") else 470,616)
 cabbage.position=Vector2(810 if after("reunion_close") else 1000,616)
 wizard.position=Vector2(275,582)
 wizard.visible=between("wizard_return","wizard_dissolve")
 if at_manor:
  pig.position=HOME_PIG
  cabbage.position=HOME_CABBAGE
  cabbage.facing=1
  cabbage.pose(false)
 if id=="manor_restore":
  pig.visible=false
  cabbage.visible=false
 if id=="return_home":
  home_arriving=false
  pig.move_blend=0.0
  cabbage.move_blend=0.0
  pig.position=Vector2(450,765)
  cabbage.position=pig.position+Vector2(-85,17)
 if after("walk_away"):
  pig.position=Vector2(1070,555)
  cabbage.position=Vector2(990,572)
 if after("final_shot"):
  pig.visible=false
  cabbage.visible=false
 hint.text="E / 空格 · 继续    Esc · 暂停    M · 静音" if not str(data[3]).is_empty() else "Esc · 暂停    M · 静音"
 chapter_label.text="" if after("wizard_return") else "猪猪山庄 · 重逢"+(" · 独立预览" if preview else "")
 words.text=data[3]
 speaker.text=data[2]
 var has_line: bool=not str(data[3]).is_empty()
 dialogue.visible=has_line
 words.visible=has_line
 speaker.visible=has_line
 if not str(data[4]).is_empty():
  memory.texture=trail_memory.get_texture() if id=="memory_trail" else MEMORIES[data[4]]
  memory.visible=true
  memory_shade.visible=true
 if id=="memory_house":
  mark("cabbage_memory_restored")
  if not preview: GameState.cabbage_emotional_state=GameState.CabbageEmotionalState.MEMORY_RETURNED
 if id=="curse_broken":
  mark("wizard_defeated")
  mark("curse_broken")
 if id=="credits":
  mark("ending_completed")
  credits.visible=true
 if after("black_pause"): curtain.color.a=1
 if id=="ending_title": title.text="猪猪山庄"
 if id=="the_end": title.text="猪猪山庄\n\nTHE END"
 if id=="credits": title.text=""
 if not preview: checkpoint(id)
 var mood := "reunion"
 if between("memory_house","memory_secret"): mood="memory"
 elif between("wizard_return","reach_hand"): mood="curse"
 elif between("hold_hands","wizard_dissolve"): mood="joy"
 elif after("curse_broken"): mood="home"
 if after("return_home"): mood="restored"
 audio.begin_scene(id)
 audio.set_mood(mood)
 _animate(0.0)
 beat_changed.emit(id)

func advance() -> void:
 if paused or mode!="cinematic" or current_id() in ["return_home","credits"]: return
 if beat_time<float(Story.BEATS[beat][1]): return
 enter_beat(beat+1)

func _process(delta: float) -> void:
 _layout()
 if not rendering_ready or paused or _pending_route: return
 beat_read_time += delta
 delta *= playback_speed()
 elapsed+=delta
 beat_time+=delta
 if mode.ends_with("path") or mode=="reunion_walk":
  _walk_path(delta)
 elif mode=="cinematic":
  _animate(delta)
  var data: Array=Story.BEATS[beat]
  var has_line: bool=not str(data[3]).is_empty()
  var waiting := current_id() in ["return_home","credits"]
  if not waiting:
   hint.text=("E / 空格 · 继续" if has_line else "")+"    Esc · 暂停    M · 静音"+("    自动对白" if auto_advance else "")
   var readable := not has_line or beat_read_time >= 1.8+str(data[3]).length()*0.16
   if beat_time>=float(data[1]) and readable and (not has_line or auto_advance): advance()
  elif current_id()=="credits": hint.text="结局已保存" if not preview and not save_error else ("独立预览 · 没有改动存档" if preview else "保存失败 · 请按 Esc 重试保存")
 audio.footsteps(pig,"pig")
 audio.footsteps(cabbage,"cabbage")
 if mode.ends_with("path") or mode=="reunion_walk": audio.timeline(current_id(),beat_time,delta)
 fx.queue_redraw()

func playback_speed() -> float:
 # Preserve deliberate recognition/response beats and all player-controlled travel.
 if mode.ends_with("path") or mode=="reunion_walk" or current_id() in ["return_home","credits"]: return 1.0
 if current_id() in ["reunion_silence","secret_pause","remember_name","remember","remember_pause","remember_you","hold_hands"]: return 1.0
 return AppSettings.story_speed

func _walk_path(delta: float) -> void:
 pig.rig.sample_cape(elapsed)
 if mode=="pig_path" and beat_time<2.8:
  _arrival_pose(beat_time)
  return
 pig.rig.brush=0.0
 pig.rig.attention=0.0
 pig.expression.dust_time=-1.0
 pig.expression.queue_redraw()
 curtain.color.a=0
 var direction := Input.get_axis("move_left","move_right")
 var actor: Node2D=cabbage if mode=="cabbage_path" else pig
 var old := path_distance
 var length := 560.0 if mode=="reunion_walk" else (2700.0 if mode=="cabbage_path" else 5100.0)
 # Once the departure fade begins, finish the last short step. Releasing the
 # key must not strand the player in a nearly black transition.
 if direction>0 and path_distance>=length-55: path_exiting=true
 if path_exiting: direction=1.0
 path_distance=clampf(path_distance+direction*170*delta,0,length)
 actor.position.x=280+path_distance
 if mode=="reunion_walk": actor.position.x=lerpf(280,470,path_distance/length)
 actor.distance+=absf(path_distance-old)*(190.0/length if mode=="reunion_walk" else 1.0)
 if absf(path_distance-old)>0.01: actor.facing=signf(path_distance-old)
 actor.pose(absf(path_distance-old)>0.01)
 _sort_actors()
 # These paths are separate setups with different characters/camera origins.
 # Reach black before swapping them, then reveal the next setup on its clock.
 curtain.color.a=maxf(1.0-smoothstep(0,.35,beat_time),smoothstep(length-55,length,path_distance))
 # Slow pan and foreground motes convey travel without stretching the artwork.
 world.position.x=-maxf(0,actor.position.x-520) if mode!="reunion_walk" else 0.0
 tint.set_shader_parameter("warmth",lerpf(0.35,0.63,path_distance/length))
 if path_distance>=length:
  if mode=="pig_path":
   mark("finale_pig_path_done")
   if preview: enter_path("cabbage_path")
   elif not has("mushroom_house_completed"): _route("res://scenes/cabbage_act2/interior.tscn")
   elif not has("finale_cabbage_path_done"): enter_path("cabbage_path")
   else: enter_path("reunion_walk")
  elif mode=="cabbage_path":
   mark("finale_cabbage_path_done")
   if not has("cave_level_completed"): _route("res://scenes/chapter2/dark_path/dark_path.tscn")
   elif not has("finale_pig_path_done"): enter_path("pig_path")
   else: enter_path("reunion_walk")
  elif reunion_ready(): enter_beat(0)

func _route(path: String) -> void:
 _pending_route=true
 if not preview:
  GameState.flags.erase("finale_checkpoint")
  SaveManager.save_game(path)
 SceneRouter.change_scene(path)

func _arrival_pose(seconds: float) -> void:
 pig.rig.sample_cape(elapsed)
 pig.facing=1
 pig.rig.attention=(1.0-smoothstep(.35,.85,seconds))*.45
 pig.rig.brush=(smoothstep(.65,.98,seconds)-smoothstep(1.06,1.28,seconds))*.95+(smoothstep(1.35,1.62,seconds)-smoothstep(1.72,2.1,seconds))*.95
 pig.pose(false)
 pig.expression.dust_time=seconds
 pig.expression.queue_redraw()
 curtain.color.a=1.0-smoothstep(0,.5,seconds)
 hint.text="Esc · 暂停    M · 静音"

func _animate(delta: float) -> void:
 var id:=current_id()
 _sample_camera(id)
 _sample_memory()
 pig.rig.sample_cape(elapsed,sin(clampf(beat_time/2.0,0,1)*PI) if id=="red_cape" else 0.0)
 var p:=clampf(beat_time/maxf(0.1,float(Story.BEATS[beat][1])),0,1)
 if id=="memory_trail": trail_memory.sample(beat_time)
 if id=="remember_you": cabbage.sample_transformation(beat_time)
 if id=="someone":
  curtain.color.a=1.0-smoothstep(0,.35,beat_time)
  var arrival:=smoothstep(.8,4.3,beat_time)
  cabbage.position=Vector2(lerpf(1640,1000,arrival),616)
  cabbage.distance=640*arrival
  cabbage.pose(beat_time>.8 and arrival<1)
  pig.rig.attention=smoothstep(.18,.7,beat_time)*(1.0-smoothstep(2.7,4.3,beat_time))
  pig.pose(false)
 if between("remember_name","remember_pause"):
  cabbage.expression.tear=smoothstep(.15,.8,beat_time) if id=="remember_name" else .8
  cabbage.expression.queue_redraw()
 if id=="reunion_close":
  pig.position.x=lerpf(470,630,smoothstep(0,1,p))
  cabbage.position.x=lerpf(1000,810,smoothstep(0,1,p))
  cabbage.distance=190*smoothstep(0,1,p)
  cabbage.pose(p>0 and p<1,sin(p*PI))
  pig.distance=160*smoothstep(0,1,p)
  pig.pose(p>0 and p<1,sin(p*PI))
 if between("close_name","reunion_rest"): pig.position.x=630
 if between("wizard_return","joy_failing"):
  pig.position.x=630
  cabbage.position.x=810
 if between("wizard_return","wizard_dissolve"):
  wizard.sample(id,beat_time)
  wizard.position=Vector2(275-28*wizard.recoil,582)
  wizard._update_material()
 if between("wizard_return","joy_failing"):
  _protect_pose(id,beat_time)
 if between("step_forward","light_travels"):
  var gesture: Dictionary = Handhold.sample(pig,cabbage,id,beat_time)
  hand_contact=gesture.contact
  hand_point=world.to_local(gesture.point) if hand_contact else Vector2.ZERO
 if after("curse_broken") and not after("manor_restore"): tint.set_shader_parameter("warmth",1.0)
 if id=="manor_restore":
  curtain.color.a=1.0-smoothstep(0,.65,beat_time)
  tint.set_shader_parameter("warmth",smoothstep(0,1,p))
  tint.set_shader_parameter("restoration_time",beat_time)
  residents.sample(beat_time)
 if after("manor_restore"): tint.set_shader_parameter("water_clock",elapsed)
 if id=="light_travels":
  world.position.y=60*p
  curtain.color.a=smoothstep(0.7,1,p)
 if id=="return_home":
  residents.sample(10.0+beat_time)
  pig.modulate.a=smoothstep(0,.45,beat_time)
  cabbage.modulate.a=pig.modulate.a
  hint.text="A / D 或 ← / → · 一起回家    Esc · 暂停"
  var direction:=Input.get_axis("move_left","move_right")
  if pig.position.x>=898: home_arriving=true
  # Use a look-ahead target so the actor can accelerate and brake without
  # multiplying a one-frame displacement by a second damping factor.
  var x:=900.0 if home_arriving else clampf(pig.position.x+direction*40,450,900)
  pig.move_to_point(Vector2(x,765-(x-450)*.31),delta,135)
  var target:=pig.position+Vector2(-85,17)
  cabbage.move_to_point(target,delta,155)
  if home_arriving and pig.position.distance_to(HOME_PIG)<.02 and cabbage.position.distance_to(HOME_CABBAGE)<.02 and maxf(pig.move_blend,cabbage.move_blend)<.001:
   enter_beat(beat+1)
 if id=="walk_away":
  _sample_walk(pig,HOME_PIG,Vector2(1070,555),p)
  _sample_walk(cabbage,HOME_CABBAGE,Vector2(990,572),p)
 if id=="leave_frame":
  _sample_walk(pig,Vector2(1070,555),Vector2(1710,515),p)
  _sample_walk(cabbage,Vector2(990,572),Vector2(1610,532),p)
 if id=="fade_out": curtain.color.a=p
 if id=="final_secret": cabbage.facing=1; cabbage.pose(false)
 _sort_actors()
 audio.timeline(id,beat_time,delta)

func _sort_actors() -> void:
 # A rig's internal z values are relative to its actor, not an independent
 # cross-character layer. Give each complete actor a separate band by feet depth.
 # In particular the pig's collar (body + 2) must not cut across the nearer face.
 var actors: Array[Node2D]=[pig,cabbage,wizard]
 actors.sort_custom(func(a: Node2D,b: Node2D):
  return a.position.y<b.position.y if not is_equal_approx(a.position.y,b.position.y) else a.get_index()<b.get_index())
 for i in actors.size(): actors[i].z_index=8+i*12

func _sample_memory() -> void:
 var blend:=smoothstep(0,.24,beat_time)
 memory.modulate.a=blend
 previous_memory.modulate.a=memory_from_alpha*(1.0-blend)
 previous_memory.visible=previous_memory.texture!=null and previous_memory.modulate.a>0
 memory_shade.modulate.a=lerpf(memory_shade_from,1.0 if memory.visible else 0.0,blend)
 memory_shade.visible=memory_shade.modulate.a>0

func _sample_camera(id: String) -> void:
 var close:=1.0 if between("first_reunion","reunion_rest") else 0.0
 if id=="first_reunion": close=smoothstep(0,.85,beat_time)
 if id=="wizard_return": close=1.0-smoothstep(0,.85,beat_time)
 world.scale=Vector2.ONE*(1.0+.06*close)
 world.position=-SIZE*.03*close
 if between("final_curse","reach_hand"):
  var weight:=smoothstep(0,.35,beat_time) if id=="final_curse" else 1.0
  if id=="reach_hand": weight=1.0-smoothstep(.8,1.2,beat_time)
  world.position+=Vector2(sin(elapsed*8),cos(elapsed*6))*1.1*weight

func _sample_walk(actor: Node2D, start: Vector2, finish: Vector2, progress: float) -> void:
 var u:=smoothstep(0,1,progress)
 actor.position=start.lerp(finish,u)
 actor.facing=1
 actor.distance=start.distance_to(finish)*u
 actor.pose(progress>0 and progress<1,sin(progress*PI))

func _protect_pose(id: String, seconds: float) -> void:
 var approach:=smoothstep(0.85,1.85,seconds) if id=="wizard_return" else 1.0
 var retreat:=smoothstep(1.8,3.0,seconds) if id=="joy_failing" else 0.0
 pig.position.x=630-28*approach*(1.0-retreat)
 pig.facing=-1 if (id!="wizard_return" or seconds>=0.85) else 1
 if id=="joy_failing" and seconds>=2.92: pig.facing=1
 pig.distance=28*approach+28*retreat
 var moving: bool=(id=="wizard_return" and seconds>0.85 and seconds<1.85) or (id=="joy_failing" and seconds>1.8 and seconds<3.0)
 var stride:=sin(clampf((seconds-.85),0,1)*PI) if id=="wizard_return" else sin(clampf((seconds-1.8)/1.2,0,1)*PI)
 pig.pose(moving,0.55*stride)
 pig.rig.guard_weight=(smoothstep(1.3,2.3,seconds) if id=="wizard_return" else 1.0)*(1.0-smoothstep(2.2,2.92,seconds) if id=="joy_failing" else 1.0)
 pig.rig.update_pose()

func _draw_curse(id: String, origin: Vector2) -> void:
 var strength: float=wizard.portal_strength
 var cracks: float=wizard.portal_break
 # The portal stays at its summon point while the wizard recoils away from it.
 for ring in 3:
  var radius:=72.0+ring*17
  for segment in 18:
   var angle:=segment*TAU/18.0
   var drift:=Vector2(cos(angle),sin(angle)*0.27)*cracks*(12+ring*5)
   fx.draw_set_transform(Vector2(275,584)+drift,0,Vector2(1,0.27))
   var end:=angle+TAU/18.0*(0.85-cracks*0.5)
   fx.draw_arc(Vector2.ZERO,radius,angle,end,8,Color(0.64,0.45,0.82,(0.45+ring*.09)*strength),1.6,true)
 fx.draw_set_transform(Vector2.ZERO)
 var cast_strength: float=wizard.cast*strength
 if cast_strength>0.01:
  var tip: Vector2=wizard.position+wizard.staff_tip()*wizard.scale
  for strand in 3:
   var points:=PackedVector2Array()
   for i in 33:
    var t:=i/32.0
    points.append(tip.lerp(origin+Vector2(-160,strand*30-30),t)+Vector2(0,sin(t*PI)*(strand-1)*46))
   fx.draw_polyline(points,Color(0.59,0.39,0.78,0.28*cast_strength*(1.0-cracks)),1.8,true)
 for ring in 3:
  var compression:=smoothstep(0,3.0,beat_time) if id=="joy_failing" else (0.0 if id in ["wizard_return","protect","things_remain","memory_objects","final_curse"] else 1.0)
  var radius:=260.0+ring*55.0-compression*70
  for segment in 14:
   var angle:=segment*TAU/14.0
   var shift:=Vector2.from_angle(angle)*cracks*28
   fx.draw_arc(origin+shift,radius,angle,angle+TAU/14.0*(0.98-cracks*.45),12,Color(0.49,0.26,0.7,0.30*strength*(1.0-cracks*.8)),2.2,true)

func _unhandled_key_input(event: InputEvent) -> void:
 if not rendering_ready: return
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode==KEY_ESCAPE:
  if paused: _resume()
  else: _show_menu()
 elif event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]: advance()
 elif event.keycode==KEY_M: audio.set_muted(not audio.muted)
 else: return
 get_viewport().set_input_as_handled()
func _show_menu() -> void:
 paused=true
 menu.visible=true
 if is_instance_valid(audio): audio.pause(true)
 menu_note.text="独立预览 · 已暂停" if preview else "已暂停"
 if mode=="blocked": menu_note.text="请先完成洞穴与蘑菇屋调查"
 menu.get_child(0).get_child(1).grab_focus()
func _resume() -> void:
 if mode=="blocked": return
 paused=false
 menu.visible=false
 audio.pause(finished)
func _save_and_exit() -> void:
 if not preview and mode!="blocked" and not checkpoint(current_id()):
  menu_note.text="保存失败，请重试"
  return
 SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")

func _draw_fx() -> void:
 var id:=current_id()
 var dark:=between("wizard_return","wizard_dissolve") if beat>=0 else false
 var joy:=between("joy_failing","light_travels") if beat>=0 else false
 var origin:=hand_point if hand_contact else Vector2(700,540)
 var fog_strength:=0.13 if not dark else 0.34
 if id=="wizard_dissolve": fog_strength*=1.0-smoothstep(0,2.6,beat_time)
 if beat>=0 and after("curse_broken"): fog_strength=0
 if id=="manor_restore": fog_strength=0.23*(1.0-smoothstep(0,1.8,beat_time))
 for i in 12:
  var at:=Vector2(fposmod(i*151+elapsed*9,1750)-100,550+sin(i*3.1+elapsed*0.3)*60)
  fx.draw_set_transform(at,0,Vector2(2.8,0.42))
  fx.draw_circle(Vector2.ZERO,100,Color(0.40,0.31,0.52,fog_strength*0.20),true,-1,true)
 fx.draw_set_transform(Vector2.ZERO)
 if dark:
  _draw_curse(id,origin)
 if joy:
  var shared := hand_contact
  var power:=1.0 if shared else 0.4
  var center:=origin if shared else Vector2(630,548)
  var contact_age:=0.0
  if shared:
   contact_age=maxf(0,beat_time-Handhold.RESPONSE_PAUSE-Handhold.RESPONSE_SECONDS) if id=="hold_hands" else .6+beat_time
   if after("hearts_return"): contact_age+=3.2
  var count:=mini(42,1+int(contact_age*16)) if shared else 42
  for i in count:
   var angle:=i*2.399+elapsed*0.32
   var radius:=48+fposmod(i*13+elapsed*17,130)*power
   if not shared: radius*=1-clampf(beat_time/5,0,0.6)
   var emerge:=smoothstep(0,.65,maxf(0,contact_age-i*.045)) if shared else 1.0
   var at:=center+Vector2(cos(angle)*radius,sin(angle)*radius*0.65)*emerge
   fx.draw_circle(at,2.0+sin(i)*0.7,Color(1.0,0.87,0.57,0.75*emerge),true,-1,true)
  if shared:
   var warmth:=smoothstep(0,.22,contact_age)
   fx.draw_circle(origin,2.6,Color(1,0.92,0.70,0.9*warmth),true,-1,true)
  if after("hearts_return"):
   for i in hearts:
    var angle:=i*TAU/maxi(hearts,1)+elapsed*0.45
    var at:=center+Vector2(cos(angle)*155,sin(angle)*75-40)
    _heart(at,12,Color(1.0,0.79,0.50,0.9))
 if id=="joy_burst":
  var radius:=beat_time*265
  for i in 12: fx.draw_arc(origin,maxf(1,radius-i*5),0,TAU,100,Color(1,0.91,0.65,0.08),8,true)
 if id=="light_travels":
  for i in 36:
   var t:=clampf((beat_time-i*0.02)/3,0,1)
   fx.draw_circle(origin.lerp(Vector2(1100,-100),t)+Vector2(sin(i*4.0)*30,cos(i*2.0)*15),2.5,Color(1,0.89,0.65,1-t),true,-1,true)
 if id=="memory_objects":
  var textures: Array=[MEMORIES.house,MEMORIES.cups,MEMORIES.gift,preload("res://assets/chapter1/heart.png"),preload("res://assets/cabbage_act2/acorn_memory/acorn_v1.png")]
  for i in textures.size():
   var at:=Vector2(400+i*175,290+sin(i*1.9)*45)
   fx.draw_texture_rect(textures[i],Rect2(at,Vector2(110,95)),false,Color(1,0.93,0.8,0.32*smoothstep(0,1,beat_time)))
 if mode.ends_with("path") or (beat>=0 and not after("fade_out")):
  for i in 12:
   var at:=Vector2(fposmod(i*173-elapsed*14,1536),fposmod(i*71+elapsed*16,700))
   fx.draw_line(at,at+Vector2(5,2),Color(0.67,0.62,0.38,0.35),2,true)
func _heart(at: Vector2, size_value: float, color: Color) -> void:
 var points:=PackedVector2Array()
 for i in 36:
  var a:=TAU*i/36
  points.append(at+Vector2(16*pow(sin(a),3),-(13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a)))*size_value/16)
 fx.draw_colored_polygon(points,color)
