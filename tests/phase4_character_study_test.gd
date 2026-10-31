extends SceneTree
const OUT := "res://docs/art_direction/phase4_boy_v1/"
func _initialize() -> void: call_deferred("run")
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.keycode=code
 event.pressed=true
 root.push_input(event,true)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await process_frame
 RenderingServer.force_draw(false)
 assert(root.get_texture().get_image().save_png(OUT+name+".png")==OK)
func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 var pig_source:=FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")
 change_scene_to_file("res://scenes/animation_studies/phase4_character_study.tscn")
 for i in 8: await process_frame
 var film:=current_scene
 film.set_process(false)
 assert(film.calibrated)
 var rig: Node2D=film.boy
 var img: Image=rig.SHEET.get_image()
 var outside:=0
 for y in img.get_height():
  for x in img.get_width():
   if img.get_pixel(x,y).a<=0.5: continue
   var included:=false
   for rect in rig.REGIONS.values():
    if rect.has_point(Vector2(x,y)): included=true;break
   if not included: outside+=1
 assert(outside==0,"Source regions crop visible artwork")
 var parts: Dictionary={}
 for part in rig.joints: parts[part]=[rig.joints[part].position,rig.artwork[part].transform]
 for f in 1681:
  film.sample(f/120.0)
  for part in parts:
   assert(rig.joints[part].position==parts[part][0] and rig.artwork[part].transform==parts[part][1],"A limb stretched or detached")
  assert(absf(maxf(rig.sole_height("Leg_A"),rig.sole_height("Leg_B")))<0.01,"Boot contour lost the ground anchor")
  assert(is_equal_approx(absf(rig.scale.x),rig.scale.y),"Facing stretched the rig")
 key(KEY_2)
 film._process(2)
 key(KEY_SPACE)
 assert(film.paused)
 var time: float=film.clock
 film._process(.25)
 assert(film.clock==time)
 key(KEY_F1)
 assert(paused)
 key(KEY_F1)
 assert(not paused and film.paused,"Settings closed an existing sample pause")
 key(KEY_R)
 assert(film.clock==0 and not film.paused)
 film._process(20)
 assert(film.clock==film.DURATION)
 key(KEY_1)
 assert(film.view==0 and film.gallery.visible)
 await capture("gallery")
 key(KEY_3)
 assert(film.view==2 and film.assembly.visible)
 await capture("joints")
 key(KEY_2)
 for t in [0.0,2.6,3.7,5.5,6.6,9.2,14.0]:
  film.sample(t)
  await capture("motion_"+str(t))
 if DisplayServer.get_name()!="headless":
  for measurement in film.measurements:
   assert(absi(measurement.visible_height-170)<=2,"Same-height comparison not calibrated")
   assert(absi(measurement.feet_y-240)<=2,"Comparison feet not aligned")
  var out:=FileAccess.open(OUT+"gallery_measurements.json",FileAccess.WRITE)
  out.store_string(JSON.stringify(film.measurements,"  "))
  out.close()
 assert(root.get_node("GameState").to_dictionary()==state)
 assert(FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")==pig_source)
 print("PHASE4_CHARACTER_STUDY_OK fixed_parts=5 sampled_poses=1681 grounding pause replay isolation graphics=",DisplayServer.get_name()!="headless")
 current_scene.queue_free()
 await process_frame
 quit()
