extends "res://scenes/action_test/movement_room.gd"
const Health = preload("res://scenes/action_test/components/player_health.gd")
const Combat = preload("res://scenes/action_test/components/player_combat.gd")
const Holder = preload("res://scenes/action_test/components/weapon_holder.gd")
## Monster kinds by name: [script, variant]. See scenes/action_test/enemies/.
const ENEMY_KINDS := {
 "slime": ["res://scenes/action_test/enemies/slime.gd", "normal"],
 "big_slime": ["res://scenes/action_test/enemies/slime.gd", "big"],
 "slime_small": ["res://scenes/action_test/enemies/slime.gd", "small"],
 "burr_hog": ["res://scenes/action_test/enemies/burr_hog.gd", ""],
 "puffcap": ["res://scenes/action_test/enemies/puffcap.gd", ""],
 "moth": ["res://scenes/action_test/enemies/moth.gd", ""],
 "acorn_spider": ["res://scenes/action_test/enemies/acorn_spider.gd", ""],
 "moss_snail": ["res://scenes/action_test/enemies/moss_snail.gd", ""]}
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
 spawn_enemy("slime",Vector2(550,900))
 h.damaged.connect(func(_dir):
  hit_feedback(player.position+Vector2(0,-40),0.04)
  camera.add_trauma(0.3))
## Adds a monster of `kind` at `at`; `options` sets script properties (patrol_width, velocity...).
func spawn_enemy(kind: String, at: Vector2, options := {}) -> CharacterBody2D:
 var entry: Array = ENEMY_KINDS[kind]
 var enemy = load(entry[0]).new()
 if entry[1]!="": enemy.variant = entry[1]
 for key in options: enemy.set(key,options[key])
 enemy.position = at
 enemy.target = player
 enemy.room = self
 world.add_child(enemy)
 enemies.append(enemy)
 enemy_added(enemy)
 return enemy
func enemy_added(_enemy: CharacterBody2D) -> void: pass
## Sound cue from a monster; rooms without sound ignore it.
func cue(kind: String) -> void:
 var fx = get("audio_fx")
 if fx: fx.cue(kind)
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
