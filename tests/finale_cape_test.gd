extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
func _initialize() -> void: call_deferred("run")
func capture() -> Image:
 await process_frame
 RenderingServer.force_draw(false)
 return root.get_texture().get_image()
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/finale/reunion_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 film.set_process(false)
 film.enter_beat(Story.index_of("red_cape"))
 film.beat_time=1
 film._animate(0)
 var body: Sprite2D=film.pig.rig.core.get_node("Body")
 var cape: MeshInstance2D=film.pig.rig.cape
 body.self_modulate.a=1
 cape.visible=false
 var original: Image=await capture()
 body.self_modulate.a=0
 cape.visible=true
 cape.sample(0,0)
 var zero: Image=await capture()
 cape.sample(2,1)
 var moving: Image=await capture()
 var atlas: AtlasTexture=body.texture
 var low:=body.to_global(Vector2(120,470)-atlas.region.position+body.offset)
 var high:=body.to_global(Vector2(415,740)-atlas.region.position+body.offset)
 var region:=Rect2(low,high-low).abs().grow(3)
 var error:=0
 var changed:=0
 var forbidden:=0
 var a:=original.get_data()
 var b:=zero.get_data()
 var c:=moving.get_data()
 var channels:=a.size()/(original.get_width()*original.get_height())
 for i in a.size():
  error=maxi(error,absi(a[i]-b[i]))
  if absi(b[i]-c[i])>3:
   changed+=1
   var pixel:=i/channels
   if not region.has_point(Vector2(pixel%original.get_width(),pixel/original.get_width())): forbidden+=1
 assert(error<=2,"Mesh changed the original resting body: "+str(error))
 assert(changed>5 and forbidden==0,"Cape moved protected body pixels")
 for entry in [[original,"cape_original"],[zero,"cape_still"],[moving,"cape_gust"]]:
  entry[0].save_png("res://docs/art_direction/finale/reunion_v2/"+entry[1]+".png")
 var out:=FileAccess.open("res://docs/art_direction/finale/reunion_v2/cape_validation.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"rest_max_channel_error":error,"moving_channels":changed,"changed_channels_outside_cloth":forbidden},"  "))
 out.close()
 print("FINALE_CAPE_OK rest_error=",error," changed_channels=",changed," outside_cloth=",forbidden)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
