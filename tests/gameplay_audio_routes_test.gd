extends SceneTree
var events: Array[String]=[]
func _initialize() -> void:
 create_timer(45).timeout.connect(func(): push_error("GAMEPLAY_AUDIO_ROUTES_TIMEOUT");quit(1))
 call_deferred("run")
func watch(bank: Node) -> void:
 events.clear()
 bank.sound_played.connect(func(kind: String): events.append(kind))
func key(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=true
 root.push_input(event,true)
func scene(path: String) -> Node:
 change_scene_to_file(path)
 for i in 4: await process_frame
 return current_scene
func run() -> void:
 await process_frame
 var state:=root.get_node("GameState")
 var router:=root.get_node("SceneRouter")
 state.reset()
 state.set_flag("s2_pig_wakeup_complete")
 state.set_flag("s2_pig_wizard_complete")
 var forest: Node=await scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")
 assert(forest.gameplay_audio.profile=="forest")
 watch(forest.gameplay_audio)
 forest.take_stick()
 assert(events==["wood_pickup"] and state.has_flag("s2_pig_stick_collected"))
 for i in 300:
  if not forest.busy: break
  forest.dialogue._advance_requested=true
  await process_frame
 assert(not forest.busy,"Pickup dialogue must finish before unloading the fixture")
 forest=await scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")
 watch(forest.gameplay_audio)
 for i in 5: await process_frame
 assert(events.is_empty(),"Loading an already held stick replayed its pickup")
 state.set_flag("s2_fragment_dropped")
 var cave: Node=await scene("res://scenes/chapter2/cave.tscn")
 assert(cave.gameplay_audio.profile=="cave")
 watch(cave.gameplay_audio)
 cave.collect_fragment()
 cave.collect_fragment()
 assert(events==["gift"],"Fragment pickup duplicated or missed its audio")
 await router.transition_finished
 var level: Node=await scene("res://scenes/finale/story_cave.tscn")
 assert(level.audio_fx.profile=="platform")
 level.set_physics_process(false)
 level.player.set_physics_process(false)
 watch(level.audio_fx)
 level.player._start_jump()
 assert("jump" in events)
 var item: Node=level.spawn_pickup("weapon",level.player.position,level.Sword)
 level.swap_weapon(item)
 assert("equip" in events)
 key(KEY_ESCAPE)
 assert(level.paused and level.audio_fx.audio_paused)
 for voice in level.audio_fx.ambience: assert(voice.stream_paused)
 key(KEY_F1)
 assert(paused)
 key(KEY_F1)
 assert(not paused and level.audio_fx.audio_paused)
 key(KEY_ESCAPE)
 assert(not level.paused and not level.audio_fx.audio_paused)
 var path: Node=await scene("res://scenes/chapter2/dark_path/dark_path.tscn")
 path.set_physics_process(false)
 watch(path.gameplay_audio)
 path._set_phase(path.Phase.CRACK)
 path._set_phase(path.Phase.FALL)
 assert(events==["crack","drop"])
 key(KEY_ESCAPE)
 assert(path.paused and path.gameplay_audio.audio_paused)
 key(KEY_ESCAPE)
 assert(not path.paused and not path.gameplay_audio.audio_paused)
 path._set_phase(path.Phase.END)
 assert(path.gameplay_audio.audio_paused)
 var house: Node=await scene("res://scenes/cabbage_act2/interior.tscn")
 var paper_audio: Node=load("res://systems/audio/gameplay_audio.gd").attach(house)
 paper_audio.cue("complete")
 house.pause_menu()
 assert(paper_audio.audio_paused and not paper_audio.cue("paper"))
 key(KEY_F1)
 key(KEY_F1)
 assert(paper_audio.audio_paused and not paused)
 house.ui.choice="stay"
 for i in 4: await process_frame
 assert(not paper_audio.audio_paused and not house.busy)
 await scene("res://scenes/bootstrap/main.tscn")
 assert(root.find_children("GameplayAudio","",true,false).is_empty(),"Menu retained gameplay ambience")
 print("GAMEPLAY_AUDIO_ROUTES_OK forest_pickup cave_fragment platform local_pause F1 dark_path paper_pause menu_cleanup")
 await create_timer(.15).timeout
 quit()
