"""Original homecoming arrangement, quoting this project's opening warm motif.
Writes only the new score. Does not re-render or overwrite existing chapter music.
"""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
out=root/'assets/audio/finale'
events=[]
beat=.75
bars=[[53,57,60,67],[52,55,60,64],[50,53,57,64],[46,53,57,62],
      [43,50,58,62],[48,55,58,64],[41,53,57,60],[48,55,60,65]]
melody=[[77,81,84,81],[79,76,72,76],[77,76,74,69],[70,74,77,74],
        [79,77,74,77],[76,79,82,79],[81,79,77,72],[79,76,72,77]]
def note(t,p,d,inst,v):
    events.append(dict(time=round(t,4),pitch=p,duration=round(min(d,48-t-.3),4),instrument=inst,velocity=v))
for bar in range(16):
    chord=bars[bar%8];t=bar*3
    for i,p in enumerate(chord[1:]):note(t+i*.018,p,2.75,48,27 if bar<8 else 32)
    note(t,chord[0]-12,2.7,42,36)
    for i,k in enumerate([0,1,2,3,2,1]):note(t+i*.5,chord[k],.9,46,43+(i%3)*3)
    pitches=melody[bar%8]
    for i,p in enumerate(pitches):note(t+i*beat,p,beat*.86,73 if bar<8 else 0,51 if bar<8 else 49)
    if bar in [3,7,11,15]:note(t+1.5,pitches[2]+12,1.05,8,33)
(out/'manor_home_v1.json').write_text(json.dumps({'duration':48,'events':events},indent=2)+'\n')
print('FINALE_HOME_SCORE_OK',len(events))
