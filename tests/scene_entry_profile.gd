extends "res://tools/review_scene_transitions.gd"
## Same visible sequence as the reported hitch; separately record CPU sampling.
var cpu_samples: Array[float]=[]
var entry_samples: Array[Dictionary]=[]
var output:="res://docs/verification/entry_2026-10-31/baseline.json"
var entered_at:=0
var previous_draw:=0
var boundary_draws: Dictionary={}

func _initialize() -> void:
 super._initialize()
 RenderingServer.frame_post_draw.connect(record_boundary)

func record_boundary() -> void:
 var now:=Time.get_ticks_usec()
 if meter!=null and previous_draw>0 and now-entered_at<600000:
  if not boundary_draws.has(str(clip)): boundary_draws[str(clip)]=[]
  boundary_draws[str(clip)].append((now-previous_draw)/1000.0)
 previous_draw=now

func make_film() -> Node:
 var result: Node=super.make_film()
 if OS.get_cmdline_user_args().has("--unprepared"):
  result.set_script(load("res://tests/scene_entry_unprepared.gd"))
  result.preview=true
 return result

func enter_clip(index: int) -> void:
 var begin:=Time.get_ticks_usec()
 super.enter_clip(index)
 entered_at=begin
 entry_samples.append({"clip":index,"cpu_ms":(Time.get_ticks_usec()-begin)/1000.0})

func sample(seconds: float) -> void:
 var begin:=Time.get_ticks_usec()
 super.sample(seconds)
 cpu_samples.append((Time.get_ticks_usec()-begin)/1000.0)

func finish() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--report="): output=arg.trim_prefix("--report=")
 var report: Dictionary=meter.finish()
 report["sample_cpu"]=Meter.stats(cpu_samples)
 report["clip_entry_cpu"]=entry_samples
 report["preparation"]=film.rendering_preparation
 report["first_600ms_after_cut"]={}
 for key in boundary_draws:
  var values: Array[float]=[]
  values.assign(boundary_draws[key])
  report.first_600ms_after_cut[key]=Meter.stats(values)
 FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 assert(root.get_node("GameState").to_dictionary()==original)
 print("SCENE_ENTRY_PROFILE_OK ",output," cpu_max=",report.sample_cpu.max_ms," draw_max=",report.draw_intervals.max_ms)
 quit(0 if report.render_coverage_valid else 1)
