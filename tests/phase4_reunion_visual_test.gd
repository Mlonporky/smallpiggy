extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
const OUT="res://docs/art_direction/phase4_boy_v1/"
func _initialize() -> void: call_deferred("run")
func draw_image() -> Image:
 await process_frame
 RenderingServer.force_draw(false)
 return root.get_texture().get_image()
func run() -> void:
 if DisplayServer.get_name()=="headless": quit(1);return
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/reunion_preview.tscn")
 for i in 4: await process_frame
 var film:=current_scene
 film.set_process(false)
 film.enter_beat(Story.index_of("remember_name"))
 film.beat_time=1
 film._animate(0)
 assert(film.cabbage.frame==4 and film.cabbage.expression.tear>0)
 var picture: Image=await draw_image()
 picture.save_png(OUT+"reunion_neutral_eye.png")
 film.enter_beat(Story.index_of("remember_you"))
 var actor: Node2D=film.cabbage
 for seconds in [0.0,1.4]:
  film.enter_beat(Story.index_of("remember_you"))
  film.beat_time=seconds
  film._animate(0)
  var transition_image: Image=await draw_image()
  transition_image.save_png(OUT+"transformation_"+str(seconds)+".png")
  var at: Vector2=actor.global_position
  var crop:=Rect2i(Vector2i(at)-Vector2i(100,190),Vector2i(200,200))
  var transition_bytes:=transition_image.get_region(crop).get_data()
  actor.configure("boy" if seconds==0 else "cabbage")
  actor.pose(false)
  var ordinary_image: Image=await draw_image()
  var ordinary_bytes:=ordinary_image.get_region(crop).get_data()
  var error:=0
  for i in transition_bytes.size(): error=maxi(error,absi(transition_bytes[i]-ordinary_bytes[i]))
  assert(error<=1,"Transformation endpoint drift after boy atlas correction")
  print("PHASE4_ENDPOINT seconds=",seconds," max_channel_error=",error)
 assert(root.get_node("GameState").to_dictionary()==state)
 print("PHASE4_REUNION_VISUAL_OK neutral_eye transformation_endpoints isolation")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
