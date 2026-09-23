extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var p = load("res://scenes/action_test/player.tscn").instantiate()
 var h = load("res://scenes/action_test/components/player_health.gd").new()
 h.name = "PlayerHealth"
 p.add_child(h)
 root.add_child(p)
 assert(h.take_damage(20,1) and h.hp==80)
 assert(not h.take_damage(20,1) and h.hp==80)
 h.tick(0.81)
 assert(h.take_damage(20,-1) and p.knockback<0)
 h.invulnerable = 0
 h.take_damage(100,1)
 assert(h.hp==0 and not p.control_enabled)
 p.reset_at(Vector2(30,50))
 assert(h.hp==100 and p.control_enabled)
 print("ACTION_HEALTH_OK")
 quit()
