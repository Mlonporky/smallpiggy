extends "res://scenes/action_test/movement_room.gd"
const Health = preload("res://scenes/action_test/components/player_health.gd")
const Combat = preload("res://scenes/action_test/components/player_combat.gd")
const Holder = preload("res://scenes/action_test/components/weapon_holder.gd")
var enemies: Array[CharacterBody2D] = []
var hit_stop := 0.0
func _ready() -> void:
 super._ready()
 var h := Health.new()
 h.name = "PlayerHealth"
 player.add_child(h)
 player.health = h
 var c := Combat.new()
 c.name = "PlayerCombat"
 player.add_child(c)
 player.combat = c
 c.weapon = preload("res://scenes/action_test/weapons/sword.tres")
 c.connected.connect(hit_feedback)
 var holder := Holder.new()
 holder.name = "WeaponHolder"
 player.visuals.add_child(holder)
 var slime = preload("res://scenes/action_test/enemies/slime.gd").new()
 slime.position = Vector2(550,900)
 slime.target = player
 slime.room = self
 world.add_child(slime)
 enemies.append(slime)
 h.damaged.connect(func(_dir):
  hit_feedback(player.position+Vector2(0,-40),0.04)
  camera.add_trauma(0.3))
func hit_feedback(at: Vector2, duration: float) -> void:
 hit_stop = maxf(hit_stop,duration)
 player.paused = true
 # Small, short shake: readable impact without swinging the whole view.
 camera.add_trauma(duration*6.5)
 burst("hit",at,1)
func _physics_process(delta: float) -> void:
 layout()
 if paused: return
 if hit_stop>0:
  hit_stop = maxf(0,hit_stop-delta)
  player.paused = hit_stop>0
  return
 player.paused = false
 super._physics_process(delta)
 for enemy in enemies: enemy.tick(delta)

func _unhandled_key_input(event: InputEvent) -> void:
 if hit_stop>0 and not paused and event is InputEventKey and not event.is_echo():
  if event.keycode==KEY_SPACE:
   if event.pressed:
    player.buffer = player.jump_buffer_time
    player.buffer_released = false
   else: player.buffer_released = true
  elif event.keycode==KEY_J and event.pressed: player.combat.queued = 0.12
 super._unhandled_key_input(event)
