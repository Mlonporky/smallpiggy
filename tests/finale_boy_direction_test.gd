extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var actor = load("res://scenes/finale/finale_actor.gd").new()
 actor.kind = "boy"
 root.add_child(actor)
 var source: Texture2D = load("res://assets/chapter1/boy.png")
 var expected := SpriteAtlas.bounds(source,3,4,PackedInt32Array([0,368,694,1028,1448]),0.10)
 assert(actor.bounds == expected)
 for side in [-1,1]:
  actor.facing = side
  var row: int = 3 if side<0 else 6
  actor.pose(false)
  assert(actor.frame == row+1,"Idle must select the feet-together middle pose")
  var fixed_scale: Vector2 = actor.sprite.scale
  for step in 8:
   actor.distance = step*26.0
   actor.pose(true)
   assert(actor.frame == row+[0,1,2,1][step%4],"Right-facing motion must never use the back row")
   assert(actor.sprite.scale == fixed_scale,"Walking must not resize each source pose")
   var region: Rect2 = actor.bounds[actor.frame]
   assert(is_zero_approx(actor.sprite.position.y+region.size.y*fixed_scale.y),"Feet anchor stays fixed")
 actor.facing = -1
 actor.pose(false)
 actor.expression.tear = 1
 assert(actor.bounds[4].has_point(Vector2(487,527)),"Eye moisture anchor belongs to the left idle frame")
 print("FINALE_BOY_DIRECTION_OK: left/right rows, neutral stop, four-step cycle, fixed scale and feet")
 actor.queue_free()
 await process_frame
 quit()
