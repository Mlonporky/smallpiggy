extends "res://tests/full_story_flow_test.gd"
var audit_index := 0
var audit_folder := "/tmp/piggy-phase12-baseline/screens"
func note(value: String) -> void:
 super.note(value)
 audit_index += 1
 snapshot.call_deferred("%02d-%s" % [audit_index,value.replace(" ","-")])
func snapshot(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 var shot := root.get_texture().get_image()
 DirAccess.make_dir_recursive_absolute(audit_folder)
 shot.save_png(audit_folder.path_join(label+".png"))
 print("AUDIT_CAPTURE ",label)
func arrived(suffix: String) -> void:
 await super.arrived(suffix)
 if suffix=="main.tscn": await snapshot("00-menu")
