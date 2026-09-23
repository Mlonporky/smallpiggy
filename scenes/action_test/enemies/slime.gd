extends "res://scenes/action_test/enemies/base_enemy.gd"
func steer(delta: float) -> void:
 var dx: float = target.position.x-position.x
 if absf(dx)<320 and absf(target.position.y-position.y)<110: facing = signf(dx)
 var probe := position+Vector2(facing*40,-8)
 var ground := PhysicsRayQueryParameters2D.create(probe,probe+Vector2(0,44),1)
 if get_world_2d().direct_space_state.intersect_ray(ground).is_empty() or is_on_wall(): facing *= -1
 velocity.x = move_toward(velocity.x,facing*46,300*delta)
