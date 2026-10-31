extends RefCounted
## Submit the real textures, mesh buffers and shader materials once in a small
## offscreen viewport. Hidden/transparent nodes do not exercise these draw paths.
## No story nodes are duplicated, sampled, repositioned or advanced here.
static func prepare(owner: Node, textures: Array[Texture2D]) -> Dictionary:
 var started:=Time.get_ticks_usec()
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(128,128)
 viewport.transparent_bg=true
 viewport.gui_disable_input=true
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 owner.add_child(viewport)
 var seen: Dictionary={}
 var pending: Array[Node]=[owner]
 var count:=0
 while not pending.is_empty():
  var source: Node=pending.pop_back()
  if source==viewport: continue
  pending.append_array(source.get_children())
  var copy: Node2D
  var rect: Rect2
  var key: String
  if source is MeshInstance2D and source.mesh!=null:
   key="mesh:%s:%s:%s" % [source.mesh.get_rid(),source.texture,source.material]
   if seen.has(key): continue
   var mesh:=MeshInstance2D.new()
   mesh.mesh=source.mesh
   mesh.texture=source.texture
   var box: AABB=source.mesh.get_aabb()
   rect=Rect2(Vector2(box.position.x,box.position.y),Vector2(box.size.x,box.size.y))
   copy=mesh
  elif source is Polygon2D and source.texture!=null and not source.polygon.is_empty():
   key="polygon:%s:%s" % [source.texture.get_rid(),source.material]
   if seen.has(key): continue
   var polygon:=Polygon2D.new()
   polygon.texture=source.texture
   polygon.polygon=source.polygon
   polygon.uv=source.uv
   rect=Rect2(source.polygon[0],Vector2.ZERO)
   for point in source.polygon: rect=rect.expand(point)
   copy=polygon
  elif (source is Sprite2D or source is TextureRect) and source.texture!=null:
   key="texture:%s:%s" % [source.texture.get_rid(),source.material]
   if seen.has(key): continue
   var sprite:=Sprite2D.new()
   sprite.texture=source.texture
   rect=sprite.get_rect()
   copy=sprite
  else: continue
  seen[key]=true
  copy.material=source.material
  _place(viewport,copy,rect,count)
  count+=1
 for texture in textures:
  if texture==null: continue
  var sprite:=Sprite2D.new()
  sprite.texture=texture
  _place(viewport,sprite,sprite.get_rect(),count)
  count+=1
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 await RenderingServer.frame_post_draw
 viewport.queue_free()
 return {"draw_resources":count,"wall_ms":(Time.get_ticks_usec()-started)/1000.0}

static func _place(viewport: SubViewport, item: Node2D, rect: Rect2, index: int) -> void:
 var factor:=14.0/maxf(1.0,maxf(rect.size.x,rect.size.y))
 item.scale=Vector2.ONE*factor
 item.position=Vector2((index%8)*16,(index/8%8)*16)-rect.position*factor
 item.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 viewport.add_child(item)
