extends Node
## Only sections 2–5 of the supplied exploration document.
const DISCOVERY := ["……", "这里怎么有一间蘑菇屋？", "奇怪。", "我怎么觉得……", "我好像忘记了什么。", "进去看看吧。"]
const UNLOCK := ["……", "我怎么会知道？", "算了。", "先进去看看。"]
const PAPER := ["这个……", "和刚才飘进屋里的那一块……", "是一样的。", "像是有人在这里包装过什么东西。", "可是……", "剩下的碎片呢？"]
var dialogue: DialogueUI
var host: Node2D
var code_input: LineEdit
var lock_panel: Control
var lock_result := ""
var test_mode := false

func _ready() -> void:
 host = get_parent()
 dialogue = preload("res://systems/dialogue/dialogue_ui.tscn").instantiate()
 dialogue.layer = 30
 add_child(dialogue)
 get_viewport().size_changed.connect(layout)
 layout()

func say(lines: Array) -> void:
 for line in lines:
  await dialogue.say("白白菜", line, 0.0, 0.35 if not test_mode and line in ["这个……", "奇怪。", "我怎么会知道？"] else 0.0, test_mode, 0.01)

func discover() -> void:
 if host.busy or GameState.has_flag("mushroom_house_discovered"): return
 host.busy = true
 host.player.set_input_enabled(false)
 host.player.face(Vector2.UP)
 await say(DISCOVERY)
 GameState.set_flag("mushroom_house_discovered")
 await release()

func release() -> void:
 await get_tree().process_frame
 host.busy = false
 host.player.set_input_enabled(true)

func enter() -> void:
 if host.busy: return
 if not GameState.has_flag("mushroom_house_discovered"): await discover()
 host.busy = true
 host.player.set_input_enabled(false)
 if not GameState.has_flag("mushroom_house_unlocked"):
  var accepted := await password()
  if not accepted:
   await release()
   return
  await get_tree().create_timer(0.5).timeout
  await say(UNLOCK)
  GameState.set_flag("mushroom_house_unlocked")
 SceneRouter.change_scene("res://scenes/cabbage_act2/interior.tscn")

func password() -> bool:
 lock_result = ""
 host.ui.shade.visible = true
 lock_panel = preload("res://scenes/cabbage_act2/combination_lock.gd").new()
 host.ui.add_child(lock_panel)
 code_input = lock_panel.code_input
 var accepted: bool = await lock_panel.finished
 lock_result = "open" if accepted else "cancel"
 lock_panel.queue_free()
 lock_panel = null
 host.ui.shade.visible = false
 return accepted

func layout() -> void:
 var size := get_viewport().get_visible_rect().size
 dialogue.panel.position = Vector2(size.x*0.11,size.y-200)
 dialogue.panel.size.x = size.x*0.78
