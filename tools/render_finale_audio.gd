extends SceneTree
func _initialize() -> void:
 var score:=preload("res://tools/finale_audio_score.gd").new()
 DirAccess.make_dir_recursive_absolute("res://assets/audio/finale")
 for mood in ["path","reunion","memory","curse","joy","home"]:
  var stream: AudioStreamWAV=score._music(mood)
  assert(stream.save_to_wav("res://assets/audio/finale/"+mood+".wav")==OK)
 assert(score._wind().save_to_wav("res://assets/audio/finale/wind.wav")==OK)
 score.free()
 print("FINALE_AUDIO_RENDERED")
 quit()
