extends SubViewport
## A deterministic excerpt of the existing acorn memory; no dialogue/state/tweens.
const Art=preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
const WALK_END:=1.6
const REACH_START:=1.85
const TOUCH:=3.0
const ATTACH:=3.22
const LIFT_END:=4.32
const DURATION:=5.2
var world: Node2D
var pig: Node2D
var cabbage: Node2D
var acorn: Sprite2D
var ground:=Vector2.ZERO
var attachment:="ground"
var atmosphere: Node2D
var sample_time:=0.0
func _ready() -> void:
 size=Vector2i(1016,572)
 transparent_bg=false
 gui_disable_input=true
 render_target_update_mode=SubViewport.UPDATE_DISABLED
 world=Node2D.new()
 world.scale=Vector2.ONE*(1016.0/1536.0)
 add_child(world)
 var background:=Sprite2D.new()
 background.texture=preload("res://assets/cabbage_act2/acorn_memory/trail_v1.png")
 background.centered=false
 background.scale=Vector2(1536,864)/background.texture.get_size()
 world.add_child(background)
 atmosphere=preload("res://scenes/cabbage_act2/acorn_memory_atmosphere.gd").new()
 world.add_child(atmosphere)
 atmosphere.set_process(false)
 cabbage=preload("res://scenes/cabbage_act2/acorn_memory_actor.gd").new()
 cabbage.visible_height=175
 world.add_child(cabbage)
 cabbage.set_process(false)
 pig=preload("res://scenes/cabbage_act2/acorn_memory_rig.gd").new()
 world.add_child(pig)
 atmosphere.pig=pig
 atmosphere.cabbage=cabbage
 pig.position=Vector2(955,642)
 pig.reach=1
 pig.update_pose()
 ground=pig.position+pig.near_hand
 for i in 9:
  var nut:=Sprite2D.new()
  nut.texture=Art.acorn()
  nut.scale=Vector2.ONE*((13.0+(i%3)*3)/Art.ACORN_REGION.size.y)
  nut.position=Vector2(460+i*77,665+(i%3)*27)
  nut.rotation=sin(i*2.8)*0.5
  world.add_child(nut)
 acorn=Sprite2D.new()
 acorn.texture=Art.acorn()
 acorn.scale=Vector2.ONE*(22.0/Art.ACORN_REGION.size.y)
 acorn.offset.y=140
 world.add_child(acorn)
 sample(0)
 render_target_update_mode=SubViewport.UPDATE_DISABLED
func sample(time: float) -> void:
 sample_time=time
 var walking:=clampf(time/WALK_END,0,1)
 var distance:=180.0*smoothstep(0,1,walking)
 pig.position=Vector2(775+distance,642)
 cabbage.position=Vector2(565+distance,642)
 pig.travel=distance
 pig.movement=pow(maxf(0,sin(walking*PI)),0.45) if time<WALK_END else 0.0
 var reach:=smoothstep(0,1,clampf((time-REACH_START)/(TOUCH-REACH_START),0,1))
 var lift:=smoothstep(0,1,clampf((time-ATTACH)/(LIFT_END-ATTACH),0,1))
 pig.reach=reach*(1-lift)
 pig.hold=lift
 pig.update_pose()
 cabbage.set_pose(int(distance/26)%4 if time<WALK_END else 0)
 attachment="hand" if time>=ATTACH else "ground"
 acorn.position=pig.position+pig.near_hand if attachment=="hand" else ground
 atmosphere.elapsed=time
 atmosphere.queue_redraw()
 render_target_update_mode=SubViewport.UPDATE_ONCE
