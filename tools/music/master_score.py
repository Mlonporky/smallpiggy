"""Level, fade, and verify the rendered stereo PCM files (requires numpy)."""
import json
from pathlib import Path
import sys
import wave
import numpy as np
root=Path(__file__).resolve().parents[2]
report={}
for name,source,loop in [('opening_story','/tmp/piggy-opening-raw.wav',False),('hollow_morning','/tmp/piggy-morning-raw.wav',True)]:
    with wave.open(source,'rb') as f:
        rate=f.getframerate(); channels=f.getnchannels()
        assert f.getsampwidth()==2 and channels==2
        x=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2).astype(np.float64)/32768
    peak=np.max(np.abs(x)); rms=np.sqrt(np.mean(x*x))
    assert peak>.001 and rms>.0001, 'Renderer produced silence'
    # Bring the phrases to a comfortable common level, retaining orchestral dynamics.
    x*=min(10**(-20/20)/rms, .70/peak)
    fade_in=int(rate*(.035 if loop else .35)); fade_out=int(rate*(.12 if loop else .7))
    x[:fade_in]*=np.linspace(0,1,fade_in)[:,None]
    x[-fade_out:]*=np.linspace(1,0,fade_out)[:,None]
    y=np.round(x*32767).astype('<i2')
    dest=root/'assets/audio/music'/f'{name}.wav'
    with wave.open(str(dest),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes(y.tobytes())
    seconds=len(x)/rate
    report[name]={'seconds':seconds,'sample_rate':rate,'channels':2,'peak_dbfs':round(20*np.log10(np.max(np.abs(x))),2),'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(x*x))),2),'clipped_samples':int(np.count_nonzero(np.abs(y)==32767)),'loop_edge_delta':float(np.max(np.abs(x[-1]-x[0])))}
    assert np.max(np.abs(x))<.71 and report[name]['clipped_samples']==0
(root/'docs/audio/music_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
