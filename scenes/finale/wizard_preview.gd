extends "res://scenes/finale/final_chapter.gd"
## Isolated continuous excerpt of the production sequence, not a separate animation.
func _ready() -> void:
 preview=true
 auto_advance=true
 super._ready()
 enter_beat(Story.index_of("wizard_return"))
func _process(delta: float) -> void:
 if not rendering_ready: return
 if finished:
  _layout()
  return
 if not paused and current_id()=="curse_broken" and beat_time+delta>=3.0:
  finished=true
  audio.pause(true)
  hint.text="空格 / E · 重看巫师演出    Esc · 菜单    M · 静音"
  return
 super._process(delta)
func _unhandled_key_input(event: InputEvent) -> void:
 if finished and not paused and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ENTER]:
  finished=false
  audio.pause(false)
  enter_beat(Story.index_of("wizard_return"))
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
