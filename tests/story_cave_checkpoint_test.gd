extends SceneTree
var room
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/piggy-story-cave-"+label+".png")
func fresh() -> void:
 change_scene_to_file("res://scenes/finale/story_cave.tscn")
 for i in 5: await process_frame
 room=current_scene
func key(code: int) -> void:
 var e:=InputEventKey.new()
 e.keycode=code
 e.physical_keycode=code
 e.pressed=true
 root.push_input(e,true)
 await physics_frame
 await physics_frame
 e=e.duplicate()
 e.pressed=false
 root.push_input(e,true)
func run() -> void:
 await process_frame
 var gs=root.get_node("GameState")
 var saves=root.get_node("SaveManager")
 saves.save_path="/tmp/piggy-story-cave-checkpoint.json"
 gs.reset()
 await fresh()
 assert(saves.load_game().ends_with("story_cave.tscn"),"Entrance is resumable")
 room.player.combat.weapon=room.Dagger
 room.player.reset_at(room.CAMPFIRES[0])
 for i in 10: await physics_frame
 assert(room.checkpoint_active)
 room.fireflies[0].taken=true
 room.firefly_count=room.fireflies.filter(func(f):return f.taken).size()
 room.secrets["cavern"]=true
 await key(KEY_F5)
 var snapshot: Dictionary=room.checkpoint_data()
 gs.reset()
 assert(saves.load_game().ends_with("story_cave.tscn"))
 await fresh()
 var restored: Dictionary=room.checkpoint_data()
 assert(absf(restored.elapsed-snapshot.elapsed)<0.5)
 restored.erase("elapsed")
 snapshot.erase("elapsed")
 assert(restored==snapshot,"JSON round trip preserves camp, weapon, collectibles and counters")
 assert(room.player.combat.weapon.kind=="dagger" and room.player.health.hp==100)
 assert(room.player.position.distance_to(room.CAMPFIRES[0])<3)
 await capture("restored")
 var count: int=room.firefly_count
 room.player.reset_at(room.fireflies[0].pos+Vector2(0,47))
 for i in 4: await physics_frame
 assert(room.firefly_count==count,"Restored fireflies cannot be awarded twice")
 await key(KEY_ESCAPE)
 assert(room.paused)
 await capture("paused")
 var before: Vector2=room.player.position
 for i in 8: await physics_frame
 assert(room.player.position==before)
 await key(KEY_S)
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.scene_file_path.ends_with("bootstrap/main.tscn"))
 assert(saves.load_game().ends_with("story_cave.tscn"))
 await fresh()
 room.leaving_cave=true
 saves.save_path="/missing-directory/piggy-test.json"
 room.complete_exit()
 assert(room.exit_save_failed and room.is_physics_processing())
 assert(gs.flags.has(room.CHECKPOINT_KEY),"Failure retains the checkpoint")
 saves.save_path="/tmp/piggy-story-cave-checkpoint.json"
 await key(KEY_ENTER)
 await root.get_node("SceneRouter").transition_finished
 assert(gs.has_flag("cave_level_completed") and not gs.flags.has("story_cave_checkpoint"))
 assert(saves.load_game().ends_with("final_chapter.tscn"))
 # Invalid optional checkpoint data falls back to a safe start.
 gs.reset()
 gs.flags["story_cave_checkpoint"]={"camp":999,"flies":[-1,999],"weapon":"unknown"}
 await fresh()
 assert(not room.checkpoint_active and room.player.position.distance_to(room.START)<3)
 for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(saves.save_path+suffix)
 print("STORY_CAVE_CHECKPOINT_OK: entrance, camp, F5, JSON reload, unique rewards, pause/menu, exit failure retry, invalid checkpoint")
 quit()
