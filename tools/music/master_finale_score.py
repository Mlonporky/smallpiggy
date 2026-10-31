"""Master rendered finale cues and wrap their reverb tails for continuous loops.
Usage: master_finale_score.py DIRECTORY_WITH_name_v2.wav
"""
import json
from pathlib import Path
import sys
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
SOURCE=Path(sys.argv[1])
OUT=ROOT/'assets/audio/finale'
report={}
for name in ['path','reunion','memory','curse','joy','afterglow']:
    key=name+'_v2'
    score=json.loads((OUT/(key+'.json')).read_text())
    with wave.open(str(SOURCE/(key+'.wav')),'rb') as f:
        rate=f.getframerate(); channels=f.getnchannels()
        assert f.getsampwidth()==2 and channels==2
        raw=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2).astype(np.float64)/32768
    count=round(score['loop_seconds']*rate)
    assert len(raw)==round(score['duration']*rate)
    audio=raw[:count].copy(); tail=raw[count:].copy()
    # Sustain the end of the previous phrase through the loop boundary. Only
    # the very end of the reverb tail is faded; the last bar stays audible.
    fade=min(len(tail),round(.3*rate))
    tail[-fade:]*=np.linspace(1,0,fade)[:,None]
    audio[:len(tail)]+=tail
    rms=np.sqrt(np.mean(audio*audio)); peak=np.max(np.abs(audio))
    assert rms>.0001 and peak>.001
    audio*=min(10**(-20/20)/rms,.7/peak)
    pcm=np.round(audio*32767).astype('<i2')
    with wave.open(str(OUT/(key+'.wav')),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(rate); f.writeframes(pcm.tobytes())
    edge=np.max(np.abs(audio[-1]-audio[0]))
    assert edge<.015 and np.max(np.abs(audio))<.701
    report[key]=dict(seconds=len(audio)/rate,sample_rate=rate,channels=2,
        peak_dbfs=round(float(20*np.log10(np.max(np.abs(audio)))),3),
        rms_dbfs=round(float(20*np.log10(np.sqrt(np.mean(audio*audio))))),
        clipped_samples=int(np.count_nonzero(np.abs(pcm.astype(np.int32))>=32767)),
        loop_edge_delta=float(edge),notes=len(score['events']))
path=ROOT/'docs/art_direction/finale/score_v2/source_validation.json'
path.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
