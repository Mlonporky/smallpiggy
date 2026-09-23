extends Node
## Short procedural cues; placeholders until recorded sound design is available.
var voices: Array[AudioStreamPlayer] = []
func _ready() -> void:
 for i in 4:
  var voice := AudioStreamPlayer.new()
  voice.volume_db = -19
  add_child(voice)
  voices.append(voice)
func cue(kind: String) -> void:
 var voice: AudioStreamPlayer = null
 for candidate in voices:
  if not candidate.playing:
   voice = candidate
   break
 if voice==null: return
 var count := 4410 if kind=="heal" else 1764
 var data := PackedByteArray()
 data.resize(count*2)
 for i in count:
  var t := float(i)/22050
  var progress := float(i)/count
  var hz := (650+650*progress) if kind=="heal" else (180-80*progress)
  var value := sin(TAU*hz*t)*(1-progress)*minf(progress*25,1)*0.45
  data.encode_s16(i*2,int(value*32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.data = data
 voice.stream = stream
 voice.play()
