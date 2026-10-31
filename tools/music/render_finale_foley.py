"""Offline original synthesized storybook foley, not field recordings.
Also masters the optional macOS-rendered 48-second home arrangement.
"""
import json, wave
from pathlib import Path
import numpy as np
root=Path(__file__).resolve().parents[2]
out=root/'assets/audio/finale';rate=44100
rng=np.random.default_rng(131026)
report={}
def save(name,x,peak=.45):
    x=np.asarray(x,dtype=np.float64)
    x*=peak/max(np.max(np.abs(x)),1e-9)
    n=min(220,len(x)//8);x[:n]*=np.linspace(0,1,n)[:,None] if x.ndim==2 else np.linspace(0,1,n)
    x[-n:]*=np.linspace(1,0,n)[:,None] if x.ndim==2 else np.linspace(1,0,n)
    y=np.round(x*32767).astype('<i2')
    with wave.open(str(out/(name+'.wav')),'wb') as f:
        f.setnchannels(2 if x.ndim==2 else 1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(y.tobytes())
    report[name]={'seconds':len(x)/rate,'channels':2 if x.ndim==2 else 1,'peak_dbfs':round(20*np.log10(np.max(np.abs(x))),2),'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(x*x))),2),'clipped_samples':int((np.abs(y)>=32767).sum()),'edge_delta':float(np.max(np.abs(x[0]-x[-1])))}
def noise(n,k):return np.convolve(rng.normal(0,1,n),np.ones(k)/k,mode='same')
for variant in range(3):
    t=np.arange(int(rate*.29))/rate
    low=noise(len(t),70+variant*13)
    grit=noise(len(t),5)-noise(len(t),35)
    envelope=(1-np.exp(-t*220))*np.exp(-t*(22+variant*2))
    x=(low*1.3+grit*.12)*envelope+np.sin(2*np.pi*(105-variant*9)*t)*envelope*.09
    save('step_earth_'+str(variant+1),x,.30)
t=np.arange(rate*16)/rate
leaf=noise(len(t),12)-noise(len(t),140)
envelope=(.3+.7*np.sin(np.pi*t/16)**2)*(.4+.6*np.sin(t*.85)**2)
save('leaves_v1',np.stack([leaf*envelope,np.roll(leaf,1900)*envelope],axis=1),.28)
t=np.arange(rate*24)/rate;birds=np.zeros((len(t),2))
for start,pan in [(1.3,-.6),(5.9,.65),(12.2,-.3),(19.0,.55)]:
    for j in range(3):
        age=np.arange(int(rate*(.12+.025*j)))/rate
        hz=2200+420*np.sin(np.pi*age/age[-1])+j*110
        phase=2*np.pi*np.cumsum(hz)/rate
        signal=(np.sin(phase)+.12*np.sin(2*phase))*np.sin(np.pi*age/age[-1])**2
        at=int((start+j*.22)*rate)
        birds[at:at+len(age),0]+=signal*np.sqrt((1-pan)/2)
        birds[at:at+len(age),1]+=signal*np.sqrt((1+pan)/2)
save('birds_v1',birds,.30)
for name,length,rising in [('curse_cast_v1',1.6,False),('joy_wave_v1',2.2,True),('dissolve_v1',2.8,False)]:
    t=np.arange(int(rate*length))/rate;env=np.sin(np.pi*t/length)**1.5
    air=noise(len(t),30 if rising else 85)
    hz=(240+180*t/length) if rising else (180-95*t/length)
    phase=2*np.pi*np.cumsum(hz)/rate
    x=air*env*.8+np.sin(phase)*env*.09
    if rising:
        for freq in [523.25,659.25,783.99]:x+=np.sin(2*np.pi*freq*t)*np.exp(-t*2)*np.minimum(t*20,1)*.055
    save(name,x,.38)
source=Path('/tmp/manor-home-v1.wav')
if source.exists():
    with wave.open(str(source),'rb') as f:
        assert f.getframerate()==rate and f.getnchannels()==2
        x=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2).astype(float)/32768
    n=int(rate*.18);x[:n]*=np.linspace(0,1,n)[:,None];x[-n:]*=np.linspace(1,0,n)[:,None]
    save('manor_home_v1',x,.65)
(root/'docs/audio/finale_audio_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
