extends "res://scenes/finale/final_chapter.gd"
## Same actors and beats as the chapter, isolated from GameState and saves.
func _ready() -> void:
 preview=true
 auto_advance=true
 super._ready()
 enter_beat(Story.index_of("joy_failing"))
func _process(delta: float) -> void:
 if not rendering_ready: return
 if finished:
  _layout()
  return
 if not paused and current_id()=="shared_joy" and beat_time+delta>=3.2:
  finished=true
  audio.pause(true)
  hint.text="空格 / E · 重看牵手动作    Esc · 菜单    M · 静音"
  return
 super._process(delta)
func _unhandled_key_input(event: InputEvent) -> void:
 if finished and not paused and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ENTER]:
  finished=false
  audio.pause(false)
  enter_beat(Story.index_of("joy_failing"))
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
