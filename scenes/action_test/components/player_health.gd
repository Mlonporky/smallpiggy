extends Node
signal damaged(direction: float)
signal died
signal healed(amount: int)
@export var max_hp := 100
@export var invincibility_duration := 0.8
var hp := 100
var invulnerable := 0.0
func tick(delta: float) -> void: invulnerable = maxf(0,invulnerable-delta)
func take_damage(amount: int, direction: float) -> bool:
 var body = get_parent()
 if hp<=0 or invulnerable>0 or body.roll_time>0: return false
 hp = maxi(0,hp-amount)
 invulnerable = invincibility_duration
 body.knockback = direction*230
 body.velocity.y = -130
 damaged.emit(direction)
 if hp==0:
  body.control_enabled = false
  died.emit()
 return true
func heal(amount: int) -> int:
 if hp<=0: return 0
 var restored := mini(amount,max_hp-hp)
 hp += restored
 if restored>0: healed.emit(restored)
 return restored
func reset_health() -> void:
 hp = max_hp
 invulnerable = 0.8
