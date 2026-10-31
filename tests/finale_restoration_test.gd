extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
var film: Node
func _initialize() -> void: call_deferred("run")
func light(image: Image, uv: Vector2) -> float:
 var pos: Vector2=film.background.to_global(uv*film.MANOR.get_size())
 var total:=0.0
 for y in range(-2,3):
  for x in range(-2,3):
   var c:=image.get_pixel(int(pos.x)+x,int(pos.y)+y)
   total+=c.r*.299+c.g*.587+c.b*.114
 return total/25
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 3: await process_frame
 film=current_scene
 film.set_process(false)
 film.enter_beat(Story.index_of("manor_restore"))
 var snapshots: Dictionary={}
 for t in [0.0,3.0,5.1,6.5,8.6,10.0]:
  film.beat_time=t
  film._animate(0)
  film.fx.queue_redraw()
  if DisplayServer.get_name()!="headless":
   await process_frame
   await RenderingServer.frame_post_draw
   var picture:=root.get_texture().get_image()
   snapshots[t]={"window":light(picture,Vector2(.579,.393)),"sky":light(picture,Vector2(.46,.13)),"water":light(picture,Vector2(.262,.484)),"grass":light(picture,Vector2(.49,.64))}
   picture.save_png("res://docs/art_direction/finale/wizard_v2/manor_"+str(t)+".png")
 if not snapshots.is_empty():
  assert(snapshots[3.0].window>snapshots[0.0].window+.12,"Window did not brighten first")
  assert(absf(snapshots[3.0].sky-snapshots[0.0].sky)<.04,"Sky restored too soon")
  assert(snapshots[6.5].water>snapshots[3.0].water+.08,"Lake did not regain reflection")
  assert(snapshots[10.0].sky>snapshots[3.0].sky+.25,"Daylight did not return")
 film.enter_beat(Story.index_of("return_home"))
 assert(film.tint.get_shader_parameter("restoration_time")==10.0)
 assert(root.get_node("GameState").to_dictionary()==original)
 print("FINALE_RESTORATION_OK ",snapshots)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 3: await process_frame
 quit()
