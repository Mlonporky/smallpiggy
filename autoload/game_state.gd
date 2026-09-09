extends Node

signal state_changed
signal heart_changed(value: int)

enum StoryPhase {
	PROLOGUE,
	CABBAGE_HOLLOW_HEART,
	LITTLE_PIG_DARK_FOREST,
	FOREST_EXPLORATION,
	FINALE,
	COMPLETED,
}

enum CabbageEmotionalState {
	HOLLOW,
	RESONATING,
	MEMORY_RETURNED,
}

var story_phase: StoryPhase = StoryPhase.PROLOGUE
var cabbage_emotional_state: CabbageEmotionalState = CabbageEmotionalState.HOLLOW
var cabbage_resonance_progress := 0
var flags: Dictionary = {}
var gift_fragments: Array[String] = []
var heart_progress := 0

func gain_chapter_heart(memory_flag: String) -> bool:
	if has_flag(memory_flag):
		return false
	flags[memory_flag] = true
	heart_progress = mini(3, heart_progress + 1)
	heart_changed.emit(heart_progress)
	state_changed.emit()
	return true


func reset() -> void:
	story_phase = StoryPhase.PROLOGUE
	cabbage_emotional_state = CabbageEmotionalState.HOLLOW
	cabbage_resonance_progress = 0
	heart_progress = 0
	flags.clear()
	gift_fragments.clear()
	state_changed.emit()
	heart_changed.emit(heart_progress)


func set_flag(flag_name: String, value := true) -> void:
	flags[flag_name] = value
	state_changed.emit()


func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))


func add_gift_fragment(fragment_id: String) -> bool:
	if fragment_id in gift_fragments:
		return false
	gift_fragments.append(fragment_id)
	state_changed.emit()
	return true


func to_dictionary() -> Dictionary:
	return {
		"version": 1,
		"heart_progress": heart_progress,
		"story_phase": int(story_phase),
		"cabbage_emotional_state": int(cabbage_emotional_state),
		"cabbage_resonance_progress": cabbage_resonance_progress,
		"flags": flags.duplicate(true),
		"gift_fragments": gift_fragments.duplicate(),
	}


func load_dictionary(data: Dictionary) -> void:
	heart_progress = clampi(int(data.get("heart_progress", 0)), 0, 3)
	story_phase = int(data.get("story_phase", StoryPhase.PROLOGUE)) as StoryPhase
	cabbage_emotional_state = int(data.get("cabbage_emotional_state", CabbageEmotionalState.HOLLOW)) as CabbageEmotionalState
	cabbage_resonance_progress = maxi(0, int(data.get("cabbage_resonance_progress", 0)))
	flags = Dictionary(data.get("flags", {})).duplicate(true)
	gift_fragments.clear()
	for fragment_id in data.get("gift_fragments", []):
		gift_fragments.append(str(fragment_id))
	state_changed.emit()
	heart_changed.emit(heart_progress)
