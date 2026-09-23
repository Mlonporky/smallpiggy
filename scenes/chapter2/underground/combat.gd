extends Node2D
const Slime = preload("res://scenes/chapter2/underground/slime.gd")
const WeaponArt = preload("res://scenes/chapter2/underground/weapon_art.gd")
const NAMES := ["未装备", "弓箭", "枪", "剑"]
const RACK := Vector2(365,730)
var room: Node2D
var pig: CharacterBody2D
var active := true
var owned: Array[int] = []
var enemies: Array[CharacterBody2D] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var slash := 0.0
var slash_origin := Vector2.ZERO
var slash_facing := 1.0
var menu: PanelContainer
var hud: Label
var prompt: Label
var result: Label
var kills := 0
var attacks := [0,0,0,0]
var hits := [0,0,0,0]

func setup(owner_room: Node2D) -> void:
 room = owner_room
 pig = room.pig
 pig.attacked.connect(_attack)
 for at in [Vector2(707,622),Vector2(1110,730),Vector2(1400,730)]:
  var enemy := Slime.new()
  enemy.position = at
  room.world.add_child(enemy)
  enemies.append(enemy)
 hud = room._label("",Vector2(64,100),23)
 prompt = room._label("",Vector2(64,764),22)
 result = room._label("",Vector2(475,195),30)
 menu = PanelContainer.new()
 menu.position = Vector2(318,200)
 menu.size = Vector2(900,370)
 var paper := StyleBoxFlat.new()
 paper.bg_color = Color("18291f")
 paper.border_color = Color("879266")
 paper.set_border_width_all(2)
 paper.set_corner_radius_all(3)
 paper.content_margin_left = 28
 paper.content_margin_right = 28
 paper.content_margin_top = 24
 paper.content_margin_bottom = 24
 menu.add_theme_stylebox_override("panel",paper)
 room.stage.add_child(menu)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",20)
 menu.add_child(stack)
 var title := Label.new()
 title.text = "武器架 · 选择一件装备"
 title.add_theme_font_size_override("font_size",30)
 stack.add_child(title)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",14)
 stack.add_child(row)
 var descriptions := ["", "弧线箭矢\n较慢 · 单发伤害高", "快速射击\n较快 · 单发伤害低", "近身挥砍\n可同时击中前方小怪"]
 for kind in range(1,4):
  var button := Button.new()
  button.text = "%d  %s\n\n%s" % [kind,NAMES[kind],descriptions[kind]]
  button.custom_minimum_size = Vector2(270,180)
  button.add_theme_font_size_override("font_size",22)
  button.pressed.connect(equip.bind(kind))
  row.add_child(button)
 var note := Label.new()
 note.text = "已拾取的武器可随时用 1 / 2 / 3 切换 · Esc 返回"
 note.add_theme_font_size_override("font_size",20)
 stack.add_child(note)
 menu.visible = false
 update_ui()

func near_rack() -> bool:
 return pig.position.distance_to(RACK)<120 and pig.is_on_floor()

func handle_key(code: int) -> bool:
 if not active: return false
 if menu.visible:
  if code==KEY_ESCAPE or code==KEY_E:
   menu.visible = false
   pig.paused = room.paused
  elif code in [KEY_1,KEY_2,KEY_3]: equip(code-KEY_0)
  return true
 if room.paused or pig.hp<=0 or not pig.enabled: return false
 if code==KEY_E and near_rack():
  menu.visible = true
  pig.paused = true
  menu.get_child(0).get_child(1).get_child(0).grab_focus()
  return true
 if code in [KEY_1,KEY_2,KEY_3]:
  var kind := code-KEY_0
  if kind in owned: pig.weapon = kind
  update_ui()
  return true
 return false

func equip(kind: int) -> void:
 if not menu.visible or not near_rack() or pig.hp<=0: return
 if not kind in owned: owned.append(kind)
 pig.weapon = kind
 menu.visible = false
 pig.paused = room.paused
 update_ui()

func update_ui() -> void:
 hud.text = "生命 %d / 100    %s    小怪 %d / 3" % [pig.hp,NAMES[pig.weapon],kills]
 if near_rack(): prompt.text = "E 选择武器    ·    已拾取：" + _owned_text()
 else: prompt.text = "1 弓箭  /  2 枪  /  3 剑（先到武器架拾取）    ·    J 攻击"
 result.text = ""
 if pig.hp<=0: result.text = "暂时倒下了 · 按 R 再试一次"
 elif kills==enemies.size(): result.text = "小怪已清理 · 按 R 再试一次"

func _owned_text() -> String:
 var names := PackedStringArray()
 for kind in owned: names.append(NAMES[kind])
 return "暂无" if names.is_empty() else "、".join(names)

func tick(delta: float) -> void:
 if not active: return
 update_ui()
 if room.paused or menu.visible or pig.hp<=0: return
 slash = maxf(0,slash-delta)
 for enemy in enemies: enemy.tick(delta,pig)
 for i in range(shots.size()-1,-1,-1):
  var shot: Dictionary = shots[i]
  var old: Vector2 = shot.pos
  if shot.kind==1: shot.vel.y += 210*delta
  var next: Vector2 = old+shot.vel*delta
  var wall := _wall(old,next)
  var end: Vector2 = wall.position if not wall.is_empty() else next
  var closest: CharacterBody2D = null
  var best := INF
  for enemy in enemies:
   if enemy.hp<=0: continue
   var center := enemy.position+Vector2(0,-27)
   var point := Geometry2D.get_closest_point_to_segment(center,old,end)
   if point.distance_to(center)<31 and old.distance_to(point)<best and _wall(old,center).is_empty():
    closest = enemy
    best = old.distance_to(point)
  shot.pos = end
  shot.life -= delta
  if closest!=null:
   _damage(closest,shot.damage,signf(shot.vel.x),shot.kind)
   shots.remove_at(i)
  elif not wall.is_empty() or shot.life<=0:
   sparks.append({"pos":end,"life":0.18})
   shots.remove_at(i)
 for i in range(sparks.size()-1,-1,-1):
  sparks[i].life -= delta
  if sparks[i].life<=0: sparks.remove_at(i)
 update_ui()
 queue_redraw()

func _wall(from: Vector2, to: Vector2) -> Dictionary:
 var query := PhysicsRayQueryParameters2D.create(from,to,1)
 return get_world_2d().direct_space_state.intersect_ray(query)

func _damage(enemy: CharacterBody2D, amount: int, direction: float, kind: int) -> void:
 var was_alive: bool = enemy.hp>0
 enemy.hit(amount,direction)
 hits[kind] += 1
 sparks.append({"pos":enemy.position+Vector2(0,-28),"life":0.18})
 if was_alive and enemy.hp<=0: kills += 1

func _attack(kind: int) -> void:
 if not active or room.paused or menu.visible or pig.hp<=0: return
 attacks[kind] += 1
 var origin := pig.position+Vector2(0,-45)
 if kind==3:
  slash = 0.22
  slash_origin = origin
  slash_facing = pig.facing
  for enemy in enemies:
   if enemy.hp<=0: continue
   var center := enemy.position+Vector2(0,-27)
   var relative := center-origin
   if relative.x*pig.facing>=-8 and relative.x*pig.facing<125 and absf(relative.y)<67 and _wall(origin,center).is_empty():
    _damage(enemy,28,pig.facing,kind)
 else:
  # Start at the body, so a muzzle overlapping a wall cannot shoot through it.
  shots.append({"pos":origin,"vel":Vector2(pig.facing*(780 if kind==1 else 1650),-65 if kind==1 else 0),"life":1.2 if kind==1 else 0.65,"damage":34 if kind==1 else 13,"kind":kind})
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(RACK+Vector2(-105,-14),Vector2(210,14)),Color("9b8063"))
 for i in range(1,4):
  var at := RACK+Vector2((i-2)*70,-56)
  draw_line(at+Vector2(0,10),at+Vector2(0,42),Color("8c7964"),5,true)
  WeaponArt.paint(self,i,at,-0.35 if i==3 else 0.0)
 for shot in shots:
  var angle: float = shot.vel.angle()
  draw_set_transform(shot.pos,angle)
  if shot.kind==1:
   draw_line(Vector2(-28,0),Vector2(7,0),Color("e5d5a9"),3,true)
   draw_colored_polygon(PackedVector2Array([Vector2(13,0),Vector2(4,-4),Vector2(4,4)]),Color("c8e4d5"))
   draw_line(Vector2(-26,-5),Vector2(-18,0),Color("d59f80"),3,true)
  else:
   draw_line(Vector2(-23,0),Vector2(5,0),Color("f5d58b"),4,true)
  draw_set_transform(Vector2.ZERO)
 if slash>0:
  draw_set_transform(slash_origin,0,Vector2(slash_facing,1))
  draw_arc(Vector2.ZERO,104,-0.85,0.85,24,Color(0.79,0.92,0.86,slash/0.22),7,true)
  draw_set_transform(Vector2.ZERO)
 for spark in sparks:
  for i in 5:
   var ray := Vector2.from_angle(i*TAU/5)
   draw_line(spark.pos+ray*6,spark.pos+ray*(20-spark.life*35),Color("f3d69a"),2,true)
