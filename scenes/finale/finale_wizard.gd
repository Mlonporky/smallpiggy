extends Node2D
## A single connected body and two rigid shoulder arms. No independent clocks.
const SHEET:=preload("res://assets/finale/wizard_parts_v2.png")
const BOUNDS:=Rect2(-120,-205,260,220)
const REGIONS:={"Body":Rect2(76,22,739,970),"Arm_A":Rect2(928,192,307,401),"Arm_B":Rect2(927,607,355,386),"Staff":Rect2(1248,58,267,935)}
const PIVOTS:={"Body":Vector2(440,982),"Arm_A":Vector2(988,261),"Arm_B":Vector2(991,662),"Staff":Vector2(1399,477)}
const GRIPS:={"Arm_A":Vector2(1175,479),"Arm_B":Vector2(1225,853)}
const SOLES:=[Vector2(280,978),Vector2(335,980),Vector2(540,980),Vector2(608,976)]
var height:=180.0
var core: Node2D
var joints: Dictionary={}
var artwork: Dictionary={}
var material_state: ShaderMaterial
var staff_mount: Node2D
var dust: Array[Dictionary]=[]
var appear:=1.0
var dissolve:=0.0
var joy_light:=0.0
var cast:=0.0
var recoil:=0.0
var timeline:=0.0
var dissolve_seconds:=0.0
var portal_strength:=0.0
var portal_break:=0.0

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 core=Node2D.new()
 add_child(core)
 material_state=ShaderMaterial.new()
 material_state.shader=preload("res://scenes/finale/wizard_dissolve.gdshader")
 for key in ["Body","Arm_A","Arm_B"]:
  var joint:=Node2D.new()
  core.add_child(joint)
  joints[key]=joint
  if key=="Arm_A": joint.position=Vector2(36,-79)
  if key=="Arm_B": joint.position=Vector2(-28,-75)
  _art(key,joint,0.188 if key=="Body" else 0.128)
 # Both arm roots are covered by the same scarf pixels as the body.
 var collar:=Polygon2D.new()
 var source:=PackedVector2Array([Vector2(275,515),Vector2(666,525),Vector2(626,597),Vector2(512,637),Vector2(358,581)])
 var local:=PackedVector2Array()
 for at in source: local.append((at-PIVOTS.Body)*0.188)
 collar.polygon=local
 collar.uv=source
 collar.texture=SHEET
 collar.material=material_state
 core.add_child(collar)
 staff_mount=Node2D.new()
 joints.Arm_A.add_child(staff_mount)
 staff_mount.position=(GRIPS.Arm_A-PIVOTS.Arm_A)*0.128
 var staff:=_art("Staff",staff_mount,0.145)
 joints.Arm_A.move_child(staff_mount,0)
 # The open palm intrudes into the staff rectangle's lower-left gutter.
 var outline:=PackedVector2Array([Vector2(1248,58),Vector2(1515,58),Vector2(1515,993),Vector2(1320,993),Vector2(1320,600),Vector2(1248,600)])
 var shape:=Polygon2D.new()
 var points:=PackedVector2Array()
 for at in outline: points.append(at-PIVOTS.Staff)
 shape.polygon=points
 shape.uv=outline
 shape.texture=SHEET
 shape.material=material_state
 staff.texture=null
 staff.add_child(shape)
 scale=Vector2.ONE*(height/(960.0*0.188))
 sample("wizard_return",0.0)
 _make_dust()

func _art(key: String, parent: Node2D, factor: float) -> Sprite2D:
 var sprite:=Sprite2D.new()
 var texture:=AtlasTexture.new()
 texture.atlas=SHEET
 texture.region=REGIONS[key]
 texture.filter_clip=true
 sprite.texture=texture
 sprite.centered=false
 sprite.offset=REGIONS[key].position-PIVOTS[key]
 sprite.scale=Vector2.ONE*factor
 sprite.material=material_state
 parent.add_child(sprite)
 artwork[key]=sprite
 return sprite

func hand_point(key: String) -> Vector2:
 return to_local(artwork[key].to_global(GRIPS[key]-PIVOTS[key]))
func staff_grip() -> Vector2:
 return to_local(staff_mount.global_position)
func staff_tip() -> Vector2:
 return to_local(artwork.Staff.to_global(Vector2(1392,242)-PIVOTS.Staff))

func sample(id: String, seconds: float) -> void:
 if not is_instance_valid(core): return
 timeline=seconds
 appear=1.0
 dissolve=0.0
 dissolve_seconds=0.0
 joy_light=0.0
 cast=0.0
 recoil=0.0
 portal_strength=1.0
 portal_break=0.0
 var pose_time:=0.0
 if id=="wizard_return":
  appear=smoothstep(0.35,2.0,seconds)
  portal_strength=smoothstep(0.0,0.7,seconds)
  pose_time=seconds
 elif id in ["protect","things_remain","memory_objects"]:
  pose_time=3.2
 elif id=="final_curse":
  cast=smoothstep(0,1.65,seconds)
  pose_time=3.2+seconds
 elif id in ["joy_failing","step_forward","reach_hand","hold_hands","shared_joy","hearts_return"]:
  cast=1.0
  pose_time=6.7
 elif id=="joy_burst":
  cast=1.0-smoothstep(0.8,2.4,seconds)*0.55
  recoil=smoothstep(0.8,2.6,seconds)
  joy_light=smoothstep(0.8,2.4,seconds)
  portal_break=smoothstep(0.9,4.0,seconds)*0.6
  pose_time=6.7
 elif id=="wizard_dissolve":
  cast=0.45
  recoil=1.0
  joy_light=1.0
  dissolve_seconds=seconds
  dissolve=clampf(seconds/2.5,0,1)
  portal_break=lerpf(0.6,1.0,smoothstep(0,3.2,seconds))
  portal_strength=1.0-smoothstep(2.4,3.5,seconds)
 else:
  appear=0.0
  portal_strength=0.0
 core.position=Vector2.ZERO
 core.rotation=0.012*sin(pose_time*5.0)*(1.0-cast)-0.105*recoil+0.025*cast
 joints.Arm_A.rotation=lerpf(-0.92,-1.38,cast)+0.18*recoil
 joints.Arm_B.rotation=lerpf(0.20,-0.95,cast)-0.18*recoil
 staff_mount.rotation=-joints.Arm_A.rotation+0.26*cast-0.18*recoil
 var floor_y:=-INF
 for point in SOLES:
  floor_y=maxf(floor_y,to_local(artwork.Body.to_global(point-PIVOTS.Body)).y)
 core.position.y=-floor_y
 _update_material()
 queue_redraw()

func _update_material() -> void:
 material_state.set_shader_parameter("actor_origin",to_global(BOUNDS.position))
 material_state.set_shader_parameter("actor_extent",BOUNDS.size*global_scale)
 material_state.set_shader_parameter("appear",appear)
 material_state.set_shader_parameter("dissolve",dissolve)
 material_state.set_shader_parameter("joy_light",joy_light)

static func _grain(at: Vector2) -> float:
 return fposmod(sin(at.dot(Vector2(127.1,311.7)))*43758.5453,1.0)
static func _soft_grain(at: Vector2) -> float:
 var cell:=at.floor()
 var f:=at-cell
 f=f*f*(Vector2(3,3)-2.0*f)
 return lerpf(lerpf(_grain(cell),_grain(cell+Vector2.RIGHT),f.x),lerpf(_grain(cell+Vector2.DOWN),_grain(cell+Vector2.ONE),f.x),f.y)
func _make_dust() -> void:
 # Sample opaque painted material, never the transparent atlas cells.
 # Store points in each part's own frame so the pose stays connected.
 for key in ["Body","Arm_A","Arm_B","Staff"]:
  var pixels: Image=SHEET.get_image().get_region(REGIONS[key])
  for y in range(7,pixels.get_height(),38):
   for x in range(7,pixels.get_width(),38):
    if pixels.get_pixel(x,y).a<0.75: continue
    var source: Vector2=Vector2(x,y)+REGIONS[key].position
    if key=="Staff" and source.x<1320 and source.y>600: continue
    dust.append({"part":key,"point":Vector2(x,y)+REGIONS[key].position-PIVOTS[key],"seed":dust.size()})

func _draw() -> void:
 if not is_instance_valid(core): return
 draw_set_transform(Vector2(0,2),0,Vector2(1,0.22))
 draw_circle(Vector2.ZERO,43,Color(0.02,0.015,0.035,0.20*appear*(1-dissolve)),true,-1,true)
 draw_set_transform(Vector2.ZERO)
 if appear>0 and dissolve<1 and cast>0:
  var at:=staff_tip()
  for ring in range(4,0,-1):
   draw_circle(at,3.0+ring*3.0,Color(0.72,0.48,0.90,0.035*cast*(1-dissolve)),true,-1,true)
 if dissolve_seconds<=0: return
 for item in dust:
  var art: Sprite2D=artwork[item.part]
  var start:=to_local(art.to_global(item.point))
  var uv: Vector2=(start-BOUNDS.position)/BOUNDS.size
  var threshold:=clampf(0.62*(1.0-uv.y)+0.38*_soft_grain(uv*Vector2(70,60)),0.02,0.98)
  var age:=dissolve_seconds-threshold*2.5
  if age<0 or age>0.95: continue
  var seed_value: float=item.seed
  var at:=start+Vector2(45.0+fmod(seed_value*7.0,45),-24.0-fmod(seed_value*13,24))*age+Vector2(0,sin(seed_value+age*5)*3*age)
  draw_circle(at,0.7+fmod(seed_value,3)*0.25,Color(0.07,0.045,0.10,(1.0-age/0.95)*0.85),true,-1,true)
