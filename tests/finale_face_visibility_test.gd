extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
const OUT="res://docs/verification/entry_2026-10-31/"
var film: Node
var results: Array[Dictionary]=[]

func _initialize() -> void: call_deferred("run")

func capture() -> Image:
 await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()

func face_difference(full: Image, isolated: Image) -> int:
 var body: Sprite2D=film.cabbage.rig.artwork.Body
 var changed:=0
 # Opaque face interior: both eyes and smile. Coordinates in the inspected
 # original cabbage atlas, transformed with the actual pose/mirror/camera.
 for y in range(435,525,4):
  for x in range(155,340,4):
   var screen: Vector2=body.get_global_transform_with_canvas()*(Vector2(x,y)-film.cabbage.rig.PIVOTS.Body)
   var point:=Vector2i(screen)
   if not Rect2i(Vector2i.ZERO,full.get_size()).has_point(point): continue
   var a:=full.get_pixelv(point)
   var b:=isolated.get_pixelv(point)
   # Source paint is slightly translucent (e.g. alpha 253/255 at 200,500).
   # Allow that background contribution; an overlaid red collar is much larger.
   if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>8.0/255: changed+=1
 return changed

func run() -> void:
 assert(DisplayServer.get_name()!="headless")
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 var source:=FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")
 film=load("res://scenes/finale/final_chapter_preview.tscn").instantiate()
 root.add_child(film)
 film.set_process(false)
 await film.wait_for_presentation()
 for i in 2: await process_frame
 film.audio.pause(true)
 film.enter_beat(Story.index_of("final_secret"))
 film.beat_time=1
 film._animate(0)
 # Reproduce the old mixed body/collar layers without changing the production file.
 film.pig.z_index=0
 film.cabbage.z_index=0
 var old:=await capture()
 film.pig.visible=false
 var isolated:=await capture()
 var old_changed:=face_difference(old,isolated)
 old.save_png(OUT+"face_before.png")
 assert(old_changed>0,"Fixture did not reproduce the reported face obstruction")
 results.append({"old_mixed_layers_occluded_face_samples":old_changed})
 film.pig.visible=true
 for sample in [["home_here",1.0],["home_promise",1.0],["walk_away",.4],["walk_away",1.5],["walk_away",2.6],["final_secret",1.0],["leave_frame",.1],["leave_frame",.6]]:
  film.enter_beat(Story.index_of(sample[0]))
  film.beat_time=sample[1]
  film.elapsed=sample[1]
  film._animate(0)
  var full:=await capture()
  film.pig.visible=false
  isolated=await capture()
  var changed:=face_difference(full,isolated)
  assert(changed==0,"Pig occluded the foreground face: "+str(sample)+" "+str(changed))
  results.append({"beat":sample[0],"time":sample[1],"occluded_face_samples":changed,"pig_layer":film.pig.z_index,"cabbage_layer":film.cabbage.z_index})
  film.pig.visible=true
  if sample[0]=="final_secret": full.save_png(OUT+"face_after.png")
 assert(root.get_node("GameState").to_dictionary()==state)
 assert(FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")==source)
 FileAccess.open(OUT+"face_visibility.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
 print("FINALE_FACE_VISIBILITY_OK old_occluded=",old_changed," fixed_poses=8 source_preserved=true")
 quit()
