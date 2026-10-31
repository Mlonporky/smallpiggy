extends "res://scenes/finale/final_chapter.gd"
## Same transformation and approach as the story; no save or GameState writes.
func _ready() -> void:
 preview = true
 auto_advance = true
 super._ready()
 enter_beat(Story.index_of("remember_you"))
func _process(delta: float) -> void:
 if not rendering_ready: return
 if finished:
  _layout()
  return
 if not paused and current_id() == "close_name" and beat_time + delta * playback_speed() >= 2.4:
  finished = true
  audio.pause(true)
  hint.text = "空格 / E · 重看恢复形态    Esc · 菜单    M · 静音"
  return
 super._process(delta)
func _unhandled_key_input(event: InputEvent) -> void:
 if finished and not paused and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_E, KEY_ENTER]:
  finished = false
  audio.pause(false)
  enter_beat(Story.index_of("remember_you"))
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
