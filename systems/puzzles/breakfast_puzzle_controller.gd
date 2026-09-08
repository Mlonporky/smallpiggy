class_name BreakfastPuzzleController
extends Node

signal puzzle_solved
signal feedback_requested(text: String)
signal item_inspected(item_id: String)
signal item_placed(item_id: String)

@export var coffee_path: NodePath
@export var cup_path: NodePath
@export var tableware_path: NodePath
@export var green_slot_path: NodePath
@export var pink_slot_path: NodePath

var coffee_made := false
var inspected: Dictionary = {"pig_cup": false, "pink_tableware": false}
var placed: Dictionary = {"pig_cup": false, "pink_tableware": false}
var held_item := ""
var completed := false

@onready var coffee: Interactable = get_node(coffee_path)
@onready var cup: Interactable = get_node(cup_path)
@onready var tableware: Interactable = get_node(tableware_path)
@onready var green_slot: Interactable = get_node(green_slot_path)
@onready var pink_slot: Interactable = get_node(pink_slot_path)


func _ready() -> void:
	coffee.interacted.connect(_on_coffee)
	cup.interacted.connect(func(_actor): _on_item("pig_cup", cup))
	tableware.interacted.connect(func(_actor): _on_item("pink_tableware", tableware))
	green_slot.interacted.connect(func(_actor): _on_slot(false))
	pink_slot.interacted.connect(func(_actor): _on_slot(true))


func _on_coffee(_actor: Node) -> void:
	if coffee_made:
		feedback_requested.emit("咖啡还温着。")
		return
	coffee_made = true
	coffee.prompt_text = "查看咖啡机"
	feedback_requested.emit("COFFEE_FIRST")


func _on_item(item_id: String, item: Interactable) -> void:
	if not coffee_made:
		feedback_requested.emit("先给自己弄点咖啡吧。")
		return
	if placed[item_id]:
		feedback_requested.emit("已经放到桌上了。")
		return
	if not inspected[item_id]:
		inspected[item_id] = true
		item_inspected.emit(item_id)
		return
	if not held_item.is_empty():
		feedback_requested.emit("手里已经拿着东西了。")
		return
	held_item = item_id
	item.visible = false
	item.set_enabled(false)
	feedback_requested.emit("拿起了%s。去看看餐桌上的使用痕迹。" % ("粉色猪猪杯" if item_id == "pig_cup" else "粉色餐具"))


func _on_slot(is_pink_slot: bool) -> void:
	if held_item.is_empty():
		feedback_requested.emit("桌面留下了两个人长期使用的痕迹。")
		return
	if not is_pink_slot:
		feedback_requested.emit("……好像不对。")
		return
	placed[held_item] = true
	item_placed.emit(held_item)
	held_item = ""
	feedback_requested.emit("……这样放，才觉得自然。") # TODO_DIALOGUE: final wording not supplied.
	if placed.values().all(func(value): return value) and not completed:
		completed = true
		puzzle_solved.emit()


func reset_held_item() -> void:
	if held_item == "pig_cup":
		cup.visible = true
		cup.set_enabled(true)
	elif held_item == "pink_tableware":
		tableware.visible = true
		tableware.set_enabled(true)
	held_item = ""
