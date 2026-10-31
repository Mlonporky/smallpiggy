extends SceneTree
var out := "/tmp/piggy-phase12-ui"
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
 await create_timer(.8).timeout
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func change(path: String) -> void:
 change_scene_to_file(path)
 for i in 4: await process_frame
func key(code: int) -> void:
 var e:=InputEventKey.new()
 e.keycode=code
 e.physical_keycode=code
 e.pressed=true
 root.push_input(e,true)
 await process_frame
 e=e.duplicate()
 e.pressed=false
 root.push_input(e,true)
 await process_frame
func run() -> void:
 await process_frame
 root.get_node("GameState").set_flag("ch1_opening_done")
 await change("res://scenes/chapter1/bedroom.tscn")
 await shot("chapter1-objective")
 current_scene.ui.inspect(preload("res://assets/prologue/bigidea_after.png"))
 await shot("chapter1-closeup")
 await key(KEY_ESCAPE)
 await key(KEY_ESCAPE)
 await shot("chapter1-pause")
 current_scene.ui.menu.get_node("settings").pressed.emit()
 await shot("chapter1-settings")
 await key(KEY_ESCAPE)
 await process_frame
 current_scene.ui.menu.get_node("stay").pressed.emit()
 await change("res://scenes/chapter2/cave.tscn")
 await shot("forest-hud")
 root.size=Vector2i(800,600)
 await shot("forest-hud-800")
 root.size=Vector2i(1152,648)
 await change("res://scenes/finale/final_chapter_preview.tscn")
 current_scene._show_menu()
 await shot("finale-pause")
 print("PHASE12_STATES_OK")
 quit()
