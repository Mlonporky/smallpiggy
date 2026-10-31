extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/restoration_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 film.set_process(false)
 var layer: Node=film.residents
 assert(layer.residents.size()==2)
 var baseline: Array=[]
 for person in layer.residents:
  baseline.append([person.a.position,person.b.position,person.art_a.scale,person.art_b.scale,person.body.scale])
 var last: Array[Vector2]=[]
 var maximum:=0.0
 for tick in 721:
  layer.sample(tick/60.0)
  for j in 2:
   var person: Dictionary=layer.residents[j]
   assert([person.a.position,person.b.position,person.art_a.scale,person.art_b.scale,person.body.scale]==baseline[j],"Resident joints or limb sizes changed")
   var tip: Vector2=person.b.to_global(Vector2(-8,16))
   if tick==0: last.append(tip)
   maximum=maxf(maximum,tip.distance_to(last[j]))
   last[j]=tip
   var lowest: float=-INF
   for foot in person.definition.feet:
    var point: Vector2=(foot-person.definition.origin)*float(person.definition.size)
    lowest=maxf(lowest,person.core.to_global(point).y)
   assert(absf(lowest-person.root.global_position.y)<.01,"Resident left ground")
 assert(maximum<2.0,"Greeting pops")
 layer.sample(6.3)
 assert(layer.recovery==0.0)
 var still: Transform2D=layer.residents[0].b.transform
 layer.sample(2.0)
 assert(still==layer.residents[0].b.transform)
 for t in [0.0,6.3,7.1,7.8,10.0]:
  film.beat_time=t
  film._animate(0)
  film.fx.queue_redraw()
  if DisplayServer.get_name()!="headless":
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/art_direction/finale/residents_v1/manor_"+str(t)+".png")
 film.enter_beat(Story.index_of("return_home"))
 assert(layer.visible and layer.recovery==1.0)
 film.enter_beat(Story.index_of("wizard_return"))
 assert(not layer.visible)
 film.enter_beat(Story.index_of("manor_restore"))
 film.beat_time=7.1
 film._animate(0)
 var frozen: Transform2D=layer.residents[0].b.global_transform
 film.paused=true
 film.set_process(true)
 await create_timer(.15).timeout
 assert(film.beat_time==7.1 and layer.residents[0].b.global_transform==frozen)
 film.paused=false
 film.set_process(false)
 film._process(20.0)
 assert(film.finished and film.beat_time==18.0 and film.current_id()=="manor_restore")
 var replay:=InputEventKey.new()
 replay.pressed=true
 replay.keycode=KEY_SPACE
 root.push_input(replay,true)
 assert(not film.finished and film.beat_time==0.0 and not film.audio.paused)
 assert(root.get_node("GameState").to_dictionary()==state)
 print("FINALE_RESIDENTS_OK samples=721 max_hand_step=",maximum)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 3: await process_frame
 quit()
