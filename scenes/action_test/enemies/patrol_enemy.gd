extends "res://scenes/action_test/enemies/base_enemy.gd"
@export var patrol_width := 200.0
func _ready() -> void:
 max_hp = 72
 stompable = false
 tint = Color("b2976b")
 super._ready()
func steer(delta: float) -> void:
 var dx: float = target.position.x-position.x
 if absf(dx)<280 and absf(target.position.y-position.y)<80: facing = signf(dx)
 if position.x<home.x-patrol_width: facing = 1
 if position.x>home.x+patrol_width: facing = -1
 var probe := position+Vector2(facing*42,-8)
 var ray := PhysicsRayQueryParameters2D.create(probe,probe+Vector2(0,48),1)
 if is_on_wall() or get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): facing *= -1
 var speed := 100.0 if absf(dx)<280 else 58.0
 velocity.x = move_toward(velocity.x,facing*speed,550*delta)
func _draw() -> void:
 super._draw()
 for x in [-24,24]: draw_line(Vector2(x,-6),Vector2(x+sin(clock*8)*7,3),Color("4a4032"),5)
