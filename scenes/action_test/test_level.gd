extends "res://scenes/action_test/combat_room.gd"
const Pickup = preload("res://scenes/action_test/components/pickup.gd")
const Sound = preload("res://scenes/action_test/components/sound_fx.gd")
const Sword = preload("res://scenes/action_test/weapons/sword.tres")
const Dagger = preload("res://scenes/action_test/weapons/dagger.tres")
const Hammer = preload("res://scenes/action_test/weapons/hammer.tres")
var pickups: Array[Node2D] = []
var checkpoint := Vector2(160,900)
var checkpoint_active := false
var death_timer := 0.0
var notice := "沿路探索 · 武器靠近按 E 拾取"
var notice_time := 4.0
var prompt: Label
var status: Label
var audio_fx: Node
var finished := false
var secrets_found := false
var nearby: Node2D
var sign_labels: Array[Label] = []
const SIGNS := [{"at":Vector2(505,772),"text":"↑ 树根上层    → 沿路前行"},{"at":Vector2(1220,1050),"text":"坑底小径 →"},{"at":Vector2(2420,840),"text":"营火"},{"at":Vector2(3090,790),"text":"尖刺不能踩 · 试试闪避"},{"at":Vector2(4470,790),"text":"出口 →"}]
var kills := 0
var weapon_icon: Node2D
var enemy_spawns := [Vector2(835,900),Vector2(1550,1120),Vector2(1860,900),Vector2(3300,900)]
var weapon_spawns := [Vector2(350,900),Vector2(1610,570),Vector2(2620,490)]
func room_platforms() -> Array:
 return [Rect2(0,900,1000,500),Rect2(1220,900,860,28),Rect2(2230,900,2570,500),Rect2(660,840,140,60),Rect2(900,750,160,24),Rect2(1170,660,160,24),Rect2(1450,570,210,24),Rect2(1770,590,190,24),Rect2(2030,660,200,24),Rect2(2310,580,190,24),Rect2(2550,490,190,24),Rect2(2800,650,170,24),Rect2(3730,820,130,80),Rect2(3980,735,130,24),Rect2(4230,820,160,80)]
func _ready() -> void:
 super._ready()
 for enemy in enemies: enemy.queue_free()
 enemies.clear()
 player.combat.weapon = null
 player.dodge_enabled = true
 player.health.died.connect(_died)
 player.health.healed.connect(_healed)
 audio_fx = Sound.new()
 add_child(audio_fx)
 player.combat.swung.connect(func(): audio_fx.cue("swing"))
 weapon_icon = Pickup.new()
 weapon_icon.kind = "weapon"
 weapon_icon.position = Vector2(1430,97)
 weapon_icon.scale = Vector2.ONE*0.65
 stage.add_child(weapon_icon)
 prompt = label("",Vector2(44,795),23)
 status = label("",Vector2(560,126),25)
 seed_room()
 for sign in SIGNS: sign_labels.append(label(sign.text,Vector2.ZERO,22))
 hud.text = "苔根小径  ·  A/D 移动  空格跳  J攻击  Shift翻滚  E拾取  F3调试\n生命 100 / 100    当前武器：空手"
func seed_room() -> void:
 for i in enemy_spawns.size():
  var script = preload("res://scenes/action_test/enemies/patrol_enemy.gd") if i==3 else preload("res://scenes/action_test/enemies/slime.gd")
  var enemy = script.new()
  enemy.position = enemy_spawns[i]
  enemy.target = player
  enemy.room = self
  enemy.defeated.connect(_enemy_dead)
  world.add_child(enemy)
  enemies.append(enemy)
 for i in weapon_spawns.size(): spawn_pickup("weapon",weapon_spawns[i],[Sword,Dagger,Hammer][i])
 for at in [Vector2(1300,900),Vector2(1930,1120)]: spawn_pickup("heal",at)
 spawn_pickup("heal",Vector2(2850,650)).amount = 40
func spawn_pickup(kind: String, at: Vector2, weapon: Resource = null) -> Node2D:
 var item := Pickup.new()
 item.kind = kind
 item.position = at
 item.weapon = weapon
 world.add_child(item)
 pickups.append(item)
 return item
func _enemy_dead(at: Vector2) -> void:
 kills += 1
 burst("hit",at+Vector2(0,-25),1.4)
 if randf()<0.25: spawn_pickup("heal",at).lock_time = 0.25
func _healed(amount: int) -> void:
 notice = "+%d HP" % amount
 notice_time = 1.8
 burst("heal",player.position+Vector2(0,-45),1.3)
 audio_fx.cue("heal")
func _died() -> void:
 death_timer = 0.85
 notice = "稍作休息 · 返回最近营火"
 notice_time = 1.5
func respawn() -> void:
 # Only the checkpoint position persists within this test run.
 for enemy in enemies: enemy.queue_free()
 enemies.clear()
 for item in pickups: item.queue_free()
 pickups.clear()
 nearby = null
 kills = 0
 particles.clear()
 finished = false
 secrets_found = false
 notice = "已从营火继续" if checkpoint_active else "从起点重新出发"
 notice_time = 1.8
 player.reset_at(checkpoint)
 player.combat.weapon = Sword if checkpoint_active else null
 camera.snap_to_target()
 seed_room()
 death_timer = 0
 hit_stop = 0
func hit_feedback(at: Vector2, duration: float) -> void:
 super.hit_feedback(at,duration)
 if audio_fx: audio_fx.cue("hit")
func _physics_process(delta: float) -> void:
 layout()
 for i in sign_labels.size():
  sign_labels[i].position = (world.get_viewport().get_canvas_transform()*SIGNS[i].at)*3
  sign_labels[i].visible = sign_labels[i].position.y>120 and sign_labels[i].position.y<775 and sign_labels[i].position.x>-100 and sign_labels[i].position.x<1500
 if paused: return
 if death_timer>0:
  death_timer -= delta
  if death_timer<=0: respawn()
  return
 super._physics_process(delta)
 if hit_stop>0: return
 if player.position.y>1300:
  _died()
  player.control_enabled = false
 if player.position.distance_to(Vector2(2380,900))<65 and not checkpoint_active:
  checkpoint = Vector2(2380,900)
  checkpoint_active = true
  player.health.heal(100)
  notice = "营火已点亮 · 从这里继续"
  notice_time = 3
  audio_fx.cue("heal")
 if player.position.distance_to(Vector2(2620,490))<90 and not secrets_found:
  secrets_found = true
  notice = "发现树根暗径"
  notice_time = 3
 if player.position.x>4570 and player.is_on_floor():
  finished = true
  notice = "已抵达出口 · 可回头探索，R从营火重试"
  notice_time = 2
 notice_time = maxf(0,notice_time-delta)
 weapon_icon.visible = player.combat.weapon!=null
 weapon_icon.weapon = player.combat.weapon
 weapon_icon.queue_redraw()
 nearby = null
 var distance := 88.0
 for item in pickups:
  item.tick(delta)
  if item.consumed or item.lock_time>0: continue
  var gap: float = player.position.distance_to(item.position)
  if item.kind=="heal" and gap<44 and player.health.hp>0:
   if player.health.heal(item.amount)>0:
    item.consumed = true
    item.visible = false
  elif item.kind=="weapon" and gap<distance:
   nearby = item
   distance = gap
 if Input.is_physical_key_pressed(KEY_E) and not e_was_down and nearby and player.alive(): swap_weapon(nearby)
 e_was_down = Input.is_physical_key_pressed(KEY_E)
 var name: String = player.combat.weapon.display_name if player.combat.weapon else "空手"
 hud.text = "苔根小径  ·  A/D 移动  空格跳  J攻击  Shift翻滚  E拾取  Esc暂停  F3调试\n生命 %d / 100    当前武器：%s    营火：%s" % [player.health.hp,name,"已点亮" if checkpoint_active else "起点"]
 prompt.text = "E 拾取 %s（替换当前武器）" % nearby.weapon.display_name if nearby else (notice if notice_time>0 else "寻找出口 · 高处与坑底都有返回路线")
 status.text = "" if not finished else "已到达出口"
 debug_label.text = "Player %s | Velocity %s | Grounded %s\nHP %d | Weapon %s | Attack %s\nDodge %.2f / CD %.2f | Invincible %.2f\nEnemy HP %s" % ["GROUND" if player.is_on_floor() else "AIR",player.velocity,player.is_on_floor(),player.health.hp,name,player.combat.state,player.roll_time,player.roll_cooldown,player.health.invulnerable,str(enemies.map(func(e): return e.hp))]
 world.queue_redraw()
var e_was_down := false
func swap_weapon(item: Node2D) -> void:
 var old: Resource = player.combat.weapon
 player.combat.reset_attack()
 player.combat.weapon = item.weapon
 item.consumed = true
 item.visible = false
 if old:
  var drop := spawn_pickup("weapon",player.position-Vector2(player.facing*36,0),old)
  drop.lock_time = 0.45
 notice = "装备了"+player.combat.weapon.display_name
 notice_time = 1.5
 audio_fx.cue("heal")
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode==KEY_R:
  respawn()
  return
 super._unhandled_key_input(event)
func draw_world() -> void:
 super.draw_world()
 world.draw_line(Vector2(2380,900),Vector2(2380,831),Color("9b7954"),6)
 world.draw_circle(Vector2(2380,828),14,Color("f0cc80") if checkpoint_active else Color("7f9072"))
 world.draw_circle(Vector2(2380,828),26,Color(0.9,0.72,0.4,0.15))
 # Small visual hints above the optional upper route, without blocking play.
 for i in 7: world.draw_line(Vector2(2530+i*35,340),Vector2(2530+i*35,375+i%3*18),Color("4b653c"),4)
