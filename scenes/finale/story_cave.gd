extends "res://scenes/action_test/test_level.gd"
## Story-only persistence. The independent action room never reads or writes saves.
const CHECKPOINT_KEY := "story_cave_checkpoint"
const NEXT_SCENE := "res://scenes/finale/final_chapter.tscn"
var leaving_cave := false
var exit_time := 0.0
var exit_save_failed := false

func seed_room() -> void:
 super.seed_room()
 # The final climb is a release of tension: no new enemies near the exit.
 for i in range(enemies.size()-1,-1,-1):
  if enemies[i].position.x>=6900:
   enemies[i].queue_free()
   enemies.remove_at(i)

func _ready() -> void:
 super._ready()
 GameState.story_phase=GameState.StoryPhase.FOREST_EXPLORATION
 restore_checkpoint()
 notice="已从营火继续 · F5 保存进度" if checkpoint_active else "沿苔根小径寻找出口 · 营火会自动保存"
 notice_time=5
 # Also persist the entrance when arriving from the falling sequence.
 save_checkpoint()

func checkpoint_data() -> Dictionary:
 var collected: Array[int] = []
 for i in fireflies.size():
  if fireflies[i].taken: collected.append(i)
 return {"camp":CAMPFIRES.find(checkpoint) if checkpoint_active else -1,
  "lit":lit_campfires.duplicate(),"weapon":checkpoint_weapon.kind if checkpoint_weapon else "",
  "flies":collected,"secrets":secrets.keys(),"elapsed":elapsed,"deaths":deaths,"kills":kills}

func save_checkpoint() -> bool:
 GameState.flags[CHECKPOINT_KEY]=checkpoint_data()
 if SaveManager.save_game(scene_file_path): return true
 notice="保存失败 · F5 重试；当前进度仍在本次游戏中"
 notice_time=8
 return false

func restore_checkpoint() -> void:
 var data: Variant = GameState.flags.get(CHECKPOINT_KEY,{})
 if not data is Dictionary: return
 var camp: Variant = data.get("camp",-1)
 if not (camp is int or camp is float) or camp != int(camp) or camp < -1 or camp >= CAMPFIRES.size(): return
 checkpoint_active = camp >= 0
 checkpoint = CAMPFIRES[int(camp)] if checkpoint_active else START
 var lit: Variant = data.get("lit",[])
 if lit is Array:
  for index in lit:
   if (index is int or index is float) and index == int(index) and index >= 0 and index < CAMPFIRES.size() and not int(index) in lit_campfires:
    lit_campfires.append(int(index))
 if checkpoint_active and not int(camp) in lit_campfires: lit_campfires.append(int(camp))
 checkpoint_weapon = {"sword":Sword,"dagger":Dagger,"hammer":Hammer}.get(str(data.get("weapon","")))
 if checkpoint_active and checkpoint_weapon == null: checkpoint_weapon= Sword
 var collected: Variant = data.get("flies",[])
 if collected is Array:
  for index in collected:
   if (index is int or index is float) and index == int(index) and index >= 0 and index < fireflies.size():
    fireflies[int(index)].taken=true
 firefly_count=fireflies.filter(func(fly): return fly.taken).size()
 var found: Variant = data.get("secrets",[])
 if found is Array:
  for key in ["cavern","nook"]:
   if key in found: secrets[key]=true
 for key in ["elapsed","deaths","kills"]:
  var value: Variant = data.get(key,0)
  if (value is int or value is float) and is_finite(float(value)):
   set(key,maxf(0,value) if key == "elapsed" else maxi(0,int(value)))
 player.reset_at(checkpoint)
 player.combat.weapon=checkpoint_weapon if checkpoint_active else null
 snap_view()

func _tick_places(delta: float) -> void:
 var previous_count := lit_campfires.size()
 super._tick_places(delta)
 if lit_campfires.size() > previous_count:
  if save_checkpoint(): notice="营火已保存 · R 返回此处，萤火与秘密保留；退出后也能续玩"

func exploration_hint() -> String:
 if player.position.x >= 6950:
  return "前方洞口将继续剧情（萤火 %d / %d）· 无需集齐；补收集可先按 R 折返" % [firefly_count,fireflies.size()]
 return super.exploration_hint()

func hud_text() -> String:
 return super.hud_text().replace("F3 调试","F5 保存")

func _physics_process(delta: float) -> void:
 if leaving_cave:
  if paused or exit_save_failed: return
  exit_time+=delta
  prompt.text="风从上面吹进来了。"
  if exit_time>=0.8: complete_exit()
  return
 super._physics_process(delta)
 if finished and player.alive() and not paused:
  leaving_cave=true
  player.control_enabled=false
  player.velocity=Vector2.ZERO
  player.paused=true
  results.visible=false
  results_panel.visible=false

func complete_exit() -> void:
 GameState.set_flag("cave_level_completed")
 GameState.flags.erase("finale_checkpoint")
 # Retain the last camp in memory until a successful transition save.
 var saved_checkpoint: Variant = GameState.flags.get(CHECKPOINT_KEY)
 GameState.flags.erase(CHECKPOINT_KEY)
 if not SaveManager.save_game(NEXT_SCENE):
  if saved_checkpoint != null: GameState.flags[CHECKPOINT_KEY]=saved_checkpoint
  exit_save_failed=true
  prompt.text="出口保存失败 · Enter 重试"
  return
 exit_save_failed=false
 set_physics_process(false)
 SceneRouter.change_scene(NEXT_SCENE,0.8)

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if leaving_cave:
  if exit_save_failed and event.keycode == KEY_ENTER: complete_exit()
  return
 if event.keycode == KEY_F5:
  if save_checkpoint():
   notice="已保存 · 继续游戏时从最近营火出发"
   notice_time=5
  get_viewport().set_input_as_handled()
  return
 if paused and event.keycode == KEY_S:
  if save_checkpoint(): SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")
  else: pause_notice.text="保存失败 · S 重试 · Esc 继续"
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
 if paused: pause_notice.text="已暂停 · Esc 继续\nF1 设置与操作\nS 保存并回菜单\n续玩从最近营火出发"
