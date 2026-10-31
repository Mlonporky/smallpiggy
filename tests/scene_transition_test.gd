extends SceneTree
var observed: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")

func run() -> void:
 await process_frame
 var router:=root.get_node("SceneRouter")
 var state:=root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 scene_changed.connect(func():
  var cover:=root.get_node_or_null("SceneTransition")
  if cover:
   assert(cover.get_child(0).color.a==1,"Scene exposed before initialization completed")
   observed.append({"scene":current_scene.scene_file_path,"cover_alpha":cover.get_child(0).color.a}))
 # Typical room transition, then a covered fall -> cave handoff.
 router.change_scene("res://scenes/chapter1/bedroom.tscn",.12)
 assert(router.is_busy())
 await router.transition_finished
 assert(current_scene.player.visible and not router.is_busy())
 await process_frame
 assert(root.get_node_or_null("SceneTransition")==null)
 router.change_scene("res://scenes/finale/story_cave.tscn",.16,true)
 assert(root.get_node("SceneTransition").get_child(0).color.a==1)
 await router.transition_finished
 assert(current_scene.scene_file_path.ends_with("story_cave.tscn") and not router.is_busy())
 await process_frame
 assert(root.get_node_or_null("SceneTransition")==null)
 # Exercise the actual close-up -> wide dissolve, including resetting UI alpha
 # so later investigation menus are not accidentally transparent.
 router.change_scene("res://scenes/chapter1/bedroom.tscn",.1)
 await router.transition_finished
 var ui: Node=current_scene.ui
 var wake: Texture2D=load("res://assets/chapter1/wake.png")
 ui.show_closeup(SpriteAtlas.frame(wake,SpriteAtlas.bounds(wake,3,1)[2]))
 current_scene.player.position=Vector2(600,565)
 ui.reveal_room(false)
 await create_timer(.12).timeout
 assert(ui.closeup.visible and ui.closeup.modulate.a>0 and ui.closeup.modulate.a<1)
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png("res://docs/verification/motion_2026-10-31/waking_dissolve.png")
 await create_timer(.45).timeout
 assert(not ui.closeup.visible and not ui.shade.visible)
 assert(ui.closeup.modulate.a==1 and ui.shade.modulate.a==1)
 assert(observed.size()==3)
 FileAccess.open("res://docs/verification/motion_2026-10-31/scene_covers.json",FileAccess.WRITE).store_string(JSON.stringify(observed,"  "))
 print("SCENE_TRANSITION_OK normal/covered routes initialized under black; waking dissolve resets UI")
 quit()
