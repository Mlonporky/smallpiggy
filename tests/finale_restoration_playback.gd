extends SceneTree
## Continuous normal-speed coverage: do not substitute static timestamp sampling.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/finale/restoration_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 var checks: Array=[]
 for at in [3.0,7.8,10.2,17.5]:
  while film.beat_time<at: await process_frame
  await RenderingServer.frame_post_draw
  var picture:=root.get_texture().get_image()
  var uv:=Vector2(.46,.13)
  var pixel: Vector2=film.background.to_global(uv*film.MANOR.get_size())
  var color:=picture.get_pixelv(Vector2i(pixel))
  checks.append({"time":film.beat_time,"uniform":film.tint.get_shader_parameter("restoration_time"),"sky":color.get_luminance()})
  picture.save_png("res://docs/art_direction/finale/residents_v1/continuous_"+str(at)+".png")
 print("RESTORATION_CONTINUOUS ",checks)
 assert(checks[2].sky>checks[0].sky+.25,"Continuous background did not restore")
 print("FINALE_RESTORATION_PLAYBACK_OK")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
