extends SceneTree
var out := "/tmp/piggy-phase12-baseline/screens"
const Story = preload("res://scenes/finale/finale_story.gd")
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
 await create_timer(1.0).timeout
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func change(path: String) -> void:
 change_scene_to_file(path)
 for i in 4: await process_frame
func run() -> void:
 await process_frame
 root.get_node("SaveManager").save_path="/tmp/piggy-phase12-capture.json"
 await change("res://scenes/prologue/prologue.tscn")
 current_scene.set_shot(0,2)
 await capture("01-opening-stable")
 await change("res://scenes/cabbage_act2/lock_preview.tscn")
 await capture("09-lock-stable")
 await change("res://scenes/cabbage_act2/wrapping_preview.tscn")
 await capture("11-paper-stable")
 await change("res://scenes/cabbage_act2/table_slide_preview.tscn")
 await capture("12-table-stable")
 await change("res://scenes/cabbage_act2/acorn_memory_final.tscn")
 await create_timer(7.0).timeout
 await capture("12b-acorn-memory")
 await change("res://scenes/chapter2/dark_path/dark_path.tscn")
 await create_timer(3.0).timeout
 await capture("14-dark-path-stable")
 await change("res://scenes/finale/final_chapter_preview.tscn")
 current_scene.enter_beat(Story.index_of("found"))
 await capture("17-reunion-dialogue")
 current_scene.enter_beat(Story.index_of("credits"))
 await capture("18-credits")
 print("AUDIT_STATES_OK")
 quit()
