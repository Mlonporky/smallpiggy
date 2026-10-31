"""Original finale arrangements using the opening's rising-third warm motif.
Only writes finale *_v2.json scores. Retains the original sketches and home theme.
A two-second render tail is wrapped into the loop by master_finale_score.py.
"""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/audio/finale'
PIANO, CELESTA, CELLO, PIZZ, HARP, STRINGS, FLUTE = 0, 8, 42, 45, 46, 48, 73
WARM = [[77,81,84,81],[79,76,72,76],[77,76,74,69],[70,74,77,74],
        [79,77,74,77],[76,79,82,79],[81,79,77,72],[79,76,72,77]]
MAJOR = [[53,57,60,67],[52,55,60,64],[50,53,57,64],[46,53,57,62],
         [43,50,58,62],[48,55,58,64],[41,53,57,60],[48,55,60,65]]
MINOR = [[50,57,64,65],[46,53,57,62],[53,57,60,64],[48,55,62,64],
         [43,50,57,58],[46,53,57,62],[45,52,55,62],[45,52,55,61]]
DARK = [[38,50,57,65],[39,51,58,67],[43,50,58,62],[45,52,58,61]]
class Score:
    def __init__(self, duration): self.length, self.events = duration, []
    def note(self, t, pitch, duration, instrument, velocity):
        if pitch is None: return
        duration = min(duration, self.length - t - .08)
        assert duration > 0
        self.events.append(dict(time=round(t,4), pitch=pitch, duration=round(duration,4), instrument=instrument, velocity=velocity))
    def pad(self, t, pitches, duration, velocity=27):
        for i,p in enumerate(pitches): self.note(t+i*.016,p,duration-i*.016,STRINGS,velocity)
    def write(self, name):
        result = dict(duration=self.length+2, loop_seconds=self.length, tail_seconds=2, events=self.events)
        (OUT/f'{name}_v2.json').write_text(json.dumps(result,indent=2)+'\n')
        print(name, self.length, len(self.events))

# The two forest paths: sparse footstep space, a searching minor answer.
s = Score(48)
for bar in range(16):
    t=bar*3; chord=MINOR[bar%8]
    s.pad(t+.04,chord[1:],2.8,24)
    s.note(t+.02,chord[0]-12,2.7,CELLO,34)
    for i in [0,2,4]: s.note(t+.12+i*.5,chord[(i//2)%4]+12,1.0,HARP,35)
    motif=[74,77,81,76] if bar%2==0 else [77,74,69,None]
    for i,p in enumerate(motif): s.note(t+.2+i*.7,p,.56,PIANO,42 if bar<8 else 46)
s.write('path')

# Reunion: warm harmony arrives gently, with rests under the repeated questions.
s = Score(48)
for bar in range(16):
    t=bar*3; chord=MAJOR[bar%8]; melody=WARM[bar%8]
    s.pad(t+.05,chord[1:],2.75,25)
    s.note(t,chord[0]-12,2.7,CELLO,32)
    for i,p in enumerate([chord[0],chord[2],chord[1],chord[3]]): s.note(t+.1+i*.7,p,1.15,HARP,36)
    for i,p in enumerate(melody):
        if i==3 and bar%2: continue
        s.note(t+.17+i*.7,p,.61,PIANO if bar<8 else FLUTE,46 if bar<8 else 40)
    if bar in [3,11]: s.note(t+1.5,melody[2]+12,.8,CELESTA,27)
s.write('reunion')

# Memory cards: unhurried piano fragments and celesta answers, no steady beat.
s = Score(32)
for bar in range(8):
    t=bar*4; chord=MAJOR[bar]; melody=WARM[bar]
    s.pad(t+.1,chord[1:3],3.7,21)
    s.note(t+.1,chord[0],3.4,HARP,28)
    s.note(t+.4,melody[0],1.5,PIANO,43)
    s.note(t+1.65,melody[1],1.2,PIANO,37)
    if bar%2==0: s.note(t+2.7,melody[2],.9,CELESTA,28)
s.write('memory')

# Last curse: restrained low strings and pizzicato, no combat percussion.
s = Score(24)
for bar in range(8):
    t=bar*3; chord=DARK[bar%4]
    s.pad(t+.02,chord[1:],2.85,33 if bar<4 else 37)
    s.note(t,chord[0],2.8,CELLO,42)
    for i in range(4): s.note(t+.12+i*.68,chord[1]+(7 if i%2 else 0),.26,PIZZ,34+(i%2)*5)
    s.note(t+.7,chord[3]+12,1.2,PIANO,33)
    if bar%2==1: s.note(t+2.1,chord[2]+12,.55,CELESTA,24)
s.write('curse')

# Shared joy: the warm motif in fuller strings and flute; intimacy over fanfare.
s = Score(32)
for bar in range(8):
    t=bar*4; chord=MAJOR[bar]; melody=WARM[bar]
    s.pad(t+.03,chord[1:]+[chord[2]+12],3.8,33+bar%3*2)
    s.note(t,chord[0]-12,3.75,CELLO,40)
    for i,k in enumerate([0,1,2,3,2,1,2,3]): s.note(t+.05+i*.48,chord[k],.85,HARP,42+i%3*3)
    for i,p in enumerate(melody): s.note(t+.18+i*.94,p,.82,FLUTE,49)
    if bar in [2,6]: s.note(t+1.9,melody[2]+12,1.4,CELESTA,30)
s.write('joy')

# Afterglow / light travelling: a lighter bridge to the existing home theme.
s = Score(32)
for bar in range(8):
    t=bar*4; chord=MAJOR[bar]; melody=WARM[bar]
    s.pad(t+.04,chord[1:],3.8,25)
    s.note(t,chord[0]-12,3.6,CELLO,31)
    for i,k in enumerate([0,2,1,3]): s.note(t+.12+i*.94,chord[k],1.6,HARP,35)
    s.note(t+.3,melody[0],1.6,FLUTE,40)
    s.note(t+2.1,melody[2],1.4,PIANO,39)
s.write('afterglow')
