extends Node2D
const Art = preload("res://scenes/chapter2/underground/weapon_art.gd")
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
 var p = get_parent().get_parent()
 if not p.combat or not p.combat.weapon: return
 var weapon = p.combat.weapon
 var face: float = p.facing if p.combat.state=="IDLE" else p.combat.attack_direction
 var angle := -0.8
 if p.combat.state=="WINDUP": angle = -1.5
 elif p.combat.state=="ACTIVE": angle = 0.25
 var at := Vector2(face*22,-46)
 if weapon.kind=="sword": Art.paint(self,3,at,angle*face,face)
 elif weapon.kind=="dagger":
  draw_set_transform(at,angle*face,Vector2(face,1))
  draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(31,-5),Vector2(45,0),Vector2(31,5),Vector2(0,5)]),Color("dedfba"))
  draw_line(Vector2(-12,0),Vector2(0,0),Color("a58161"),7)
  draw_set_transform(Vector2.ZERO)
 else:
  draw_set_transform(at,angle*face,Vector2(face,1))
  draw_line(Vector2(-12,0),Vector2(63,0),Color("947452"),7)
  draw_rect(Rect2(44,-19,32,38),Color("92998b"))
  draw_rect(Rect2(44,-19,32,6),Color("c0c6a9"))
  draw_set_transform(Vector2.ZERO)
