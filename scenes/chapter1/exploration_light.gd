extends Node2D
## Lighting uses the pictured objects, independently of their reachable floor hotspots.
const CLUES := {
 "bedroom": [["painting", Vector2(375,170), Vector2(125,140), "big_idea_checked"]],
 "kitchen": [["cup", Vector2(1005,348), Vector2(70,65), "pig_cup_checked"],
  ["tableware", Vector2(725,745), Vector2(215,120), "double_tableware_checked"]],
 "living": [["pillow", Vector2(690,435), Vector2(135,115), "pig_pillow_checked"],
  ["paper", Vector2(710,875), Vector2(75,65), "red_paper_checked"]]
}
var room: Node2D
var clues: Array
var lighting: ShaderMaterial
var elapsed := 0.0
var strengths := PackedFloat32Array([0,0,0,0])

func _ready() -> void:
 name = "ExplorationLight"
 z_index = 20
 room = get_parent()
 clues = CLUES[room.room_id]
 var veil := Polygon2D.new()
 veil.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1448,0),Vector2(1448,1086),Vector2(0,1086)])
 lighting = ShaderMaterial.new()
 lighting.shader = preload("res://scenes/chapter1/exploration_light.gdshader")
 veil.material = lighting
 add_child(veil)
 # Draw markers after the dimming layer.
 var markers := Node2D.new()
 markers.draw.connect(_draw_markers.bind(markers))
 markers.name = "Markers"
 add_child(markers)
 _process(0.0)

func _process(delta: float) -> void:
 elapsed += delta
 var spots := PackedVector4Array()
 for i in 4:
  if i >= clues.size():
   spots.append(Vector4(0,0,1,1))
   continue
  var clue: Array = clues[i]
  var pos: Vector2 = clue[1]
  if clue[0] == "paper" and is_instance_valid(room.paper): pos = room.paper.position
  spots.append(Vector4(pos.x,pos.y,clue[2].x,clue[2].y))
  var target := 0.38
  if GameState.has_flag(clue[3]): target = 0.18
  if clue[0] == "paper" and not GameState.has_flag("red_paper_spawned"): target = 0.0
  strengths[i] = move_toward(strengths[i],target,delta*0.9)
 lighting.set_shader_parameter("spots",spots)
 lighting.set_shader_parameter("strengths",strengths)
 lighting.set_shader_parameter("clock",elapsed)
 $Markers.queue_redraw()

func _draw_markers(canvas: Node2D) -> void:
 if room.busy: return
 for i in clues.size():
  var clue: Array = clues[i]
  if GameState.has_flag(clue[3]) or strengths[i] < 0.1: continue
  if clue[0] == "cup" and not GameState.has_flag("coffee_made"): continue
  var pos: Vector2 = clue[1] - Vector2(0,clue[2].y*0.55)
  var pulse := 0.7 + 0.3*sin(elapsed*1.65 + i)
  draw_spark(canvas,pos+Vector2(0,sin(elapsed*1.2+i)*4),pulse)
  # A small floor glimmer tells players where the object can be reached.
  var foot: Vector2 = room.hotspots[clue[0]].position
  if clue[0] not in ["cup","tableware"]:
   canvas.draw_arc(foot,18,0,TAU,40,Color(1.0,0.80,0.46,0.36*pulse),2,true)
 if room.room_id == "kitchen" and not GameState.has_flag("trash_checked"):
  draw_spark(canvas,Vector2(1225,405),0.7+0.3*sin(elapsed*1.65+2.0))
 if room.room_id == "kitchen" and not GameState.has_flag("coffee_made"):
  draw_spark(canvas,Vector2(1120,235),0.65)
  canvas.draw_arc(room.hotspots.coffee.position,18,0,TAU,40,Color(1,0.8,0.46,0.3),2,true)

func draw_spark(canvas: Node2D, pos: Vector2, alpha: float) -> void:
 for radius in [14,10,6]:
  canvas.draw_circle(pos,radius,Color(1.0,0.72,0.32,0.06*alpha))
 var shape := PackedVector2Array([pos+Vector2(0,-8),pos+Vector2(2,-2),pos+Vector2(7,0),pos+Vector2(2,2),pos+Vector2(0,8),pos+Vector2(-2,2),pos+Vector2(-7,0),pos+Vector2(-2,-2)])
 canvas.draw_colored_polygon(shape,Color(1.0,0.89,0.62,alpha))
