extends SceneTree
const Art := preload("res://scenes/cabbage_act2/wrapping_art.gd")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 await process_frame
 for i in 5:
  var viewport := SubViewport.new()
  viewport.transparent_bg = true
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  viewport.size = Vector2i(Art.bounds(i).size*3+Vector2(12,12)) if i < 4 else Vector2i(1200,800)
  root.add_child(viewport)
  var artwork: Node2D = Art.make_piece(i) if i < 4 else Art.make_whole(true)
  artwork.scale = Vector2.ONE*3 if i < 4 else Vector2.ONE*2
  artwork.position = Vector2(viewport.size)*0.5 if i < 4 else Vector2.ZERO
  viewport.add_child(artwork)
  await process_frame
  await RenderingServer.frame_post_draw
  var filename := "piece_%d.png" % (i+1) if i < 4 else "back_message.png"
  var error := viewport.get_texture().get_image().save_png("res://assets/cabbage_act2/wrapping/"+filename)
  assert(error == OK)
  viewport.queue_free()
 print("WRAPPING_ART_EXPORTED")
 quit()
