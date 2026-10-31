extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 film.set_process(false)
 film.enter_beat(Story.index_of("memory_trail"))
 var clip: Node=film.trail_memory
 var previous: Vector2=clip.acorn.position
 var maximum:=0.0
 for i in 625:
  var t:=i/120.0
  film.beat_time=t
  film._animate(1.0/120.0)
  var at: Vector2=clip.acorn.position
  maximum=maxf(maximum,at.distance_to(previous))
  previous=at
  if t<clip.ATTACH: assert(at.distance_to(clip.ground)<0.01,"Acorn lifted before contact")
  else: assert(at.distance_to(clip.pig.position+clip.pig.near_hand)<0.01)
 clip.sample(clip.TOUCH)
 assert((clip.pig.position+clip.pig.near_hand).distance_to(clip.ground)<0.01,"No physical contact")
 assert(maximum<2.0,"Acorn jumps at attachment: "+str(maximum))
 if DisplayServer.get_name()!="headless":
  for sample in [["trail_walk",0.8],["trail_touch",3.1],["trail_lift",4.5]]:
   clip.sample(sample[1])
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/art_direction/finale/handhold_v2/"+sample[0]+".png")
 film.enter_beat(Story.index_of("memory_cape"))
 assert(clip.render_target_update_mode==SubViewport.UPDATE_DISABLED)
 assert(root.get_node("GameState").to_dictionary()==original)
 print("FINALE_TRAIL_MEMORY_OK max_acorn_step=",maximum)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 3: await process_frame
 quit()
