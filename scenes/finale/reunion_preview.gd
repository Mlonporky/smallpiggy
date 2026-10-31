extends "res://scenes/finale/final_chapter.gd"
## Selected acting shots; omitted memory montage is explicit in the preview title.
const SHOTS := [["pig_path",2.8],["someone",4.3],["reunion_silence",1.0],["first_reunion",2.28],["red_cape",2.0],["remember_name",2.44],["remember",2.76],["remember_pause",.8],["remember_you",2.44],["reunion_close",2.0],["found",3.08]]
var shot := 0
func _ready() -> void:
 preview=true
 auto_advance=false
 super._ready()
 _enter_shot(0)
func _enter_shot(index: int) -> void:
 shot=index
 if SHOTS[shot][0]=="pig_path":
  enter_path("pig_path")
  _arrival_pose(0.0)
  audio.timeline("pig_path",0,0)
 else: enter_beat(Story.index_of(SHOTS[shot][0]))
 chapter_label.text="重逢动作 · 剪选样片（省略回忆蒙太奇）"
func _process(delta: float) -> void:
 _layout()
 if finished or paused: return
 delta *= playback_speed()
 elapsed+=delta
 beat_time+=delta
 if shot==0:
  _arrival_pose(beat_time)
  audio.timeline("pig_path",beat_time,delta)
 else: _animate(delta)
 audio.footsteps(pig,"pig")
 audio.footsteps(cabbage,"cabbage")
 fx.queue_redraw()
 if beat_time>=float(SHOTS[shot][1]):
  if shot+1<SHOTS.size(): _enter_shot(shot+1)
  else:
   finished=true
   audio.pause(true)
   hint.text="空格 / E · 重看重逢样片    Esc · 菜单    M · 静音"
func advance() -> void:
 if paused or finished: return
 if shot+1<SHOTS.size(): _enter_shot(shot+1)
func _unhandled_key_input(event: InputEvent) -> void:
 if finished and not paused and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ENTER]:
  finished=false
  audio.pause(false)
  _enter_shot(0)
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
