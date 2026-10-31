"""Original Piggy Manor themes, authored as notes and scene-timed orchestration.
No downloaded songs, recordings, or generative music service is used.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/audio/music"
PIANO, CELESTA, CELLO, PIZZ, HARP, STRINGS, FLUTE = 0, 8, 42, 45, 46, 48, 73

class Score:
    def __init__(self, duration):
        self.duration, self.events = duration, []
    def note(self, t, pitch, duration, instrument, velocity=52):
        if pitch is None or t >= self.duration - 0.4:
            return
        duration = min(duration, self.duration-t-0.25)
        self.events.append(dict(time=round(t,4), pitch=pitch, duration=round(duration,4),
                                instrument=instrument, velocity=velocity))
    def chord(self, t, pitches, duration, instrument=STRINGS, velocity=37):
        for i, pitch in enumerate(pitches):
            self.note(t+i*.018, pitch, duration-i*.018, instrument, velocity)
    def phrase(self, t, notes, beat=.75, instrument=PIANO, velocity=61):
        for i,(pitch,beats) in enumerate(notes):
            self.note(t,pitch,beats*beat*.87,instrument,velocity+(i%3-1)*3)
            t += beats*beat
    def write(self, name):
        (OUT / (name+".json")).write_text(json.dumps(dict(duration=self.duration,events=self.events),indent=2)+"\n")

# A small rising third is shared by the warm theme and its hollow, minor answer.
WARM = [
 [(77,1),(81,.5),(84,.5),(81,1)], [(79,1.5),(76,.5),(72,1)],
 [(77,1),(76,.5),(74,.5),(69,1)], [(70,1.5),(74,.5),(77,1)],
 [(79,1),(77,1),(74,1)], [(76,1),(79,.5),(82,.5),(79,1)],
 [(81,1),(79,.5),(77,.5),(72,1)], [(79,1),(76,1),(None,1)]
]
CHORDS = [[53,57,60,67],[52,55,60,64],[50,53,57,64],[46,53,57,62],
          [43,50,58,62],[48,55,58,64],[41,53,57,60],[48,55,60,65]]

opening = Score(88.5)
opening.chord(.05,[50,57,64,65],3.2,velocity=31)
opening.note(.15,38,3.1,CELLO,40)
opening.phrase(.9,[(81,1),(76,1),(77,1)],.65,CELESTA,44)
# Leave room for the existing crystal alarm instead of doubling its beeps.
opening.chord(3.55,[50,57,65,70],4.1,velocity=39)
opening.note(3.6,38,4,CELLO,42)
for t in [4.1,5.6,7.1]: opening.note(t,50,.28,PIZZ,42)
for j,chord in enumerate([[50,57,64,65],[46,53,57,62],[43,50,57,58],[45,52,55,61]]):
    t = 8+j*3.5
    opening.chord(t,chord,3.2,velocity=35+j)
    opening.note(t,chord[0]-12,3.2,CELLO,40)
    opening.phrase(t+.4,[(chord[2],1),(chord[3],.5),(chord[1],1),(None,1)],.7,PIANO,52)
    if j%2==0: opening.note(t+2.5,chord[2]+12,.7,CELESTA,38)
for j,chord in enumerate(CHORDS):
    t = 22+j*2.25
    opening.chord(t,chord,2.1,velocity=27)
    for i,pitch in enumerate([chord[0],chord[1],chord[2],chord[3],chord[2],chord[1]]):
        opening.note(t+i*.375,pitch,.65,HARP,45+(i%2)*6)
    opening.phrase(t+.04,WARM[j],.75,FLUTE if j<4 else CELESTA,57 if j<4 else 50)
# Arrival: a restrained low ostinato and a rising inner voice.
for j,chord in enumerate([[38,50,57,65],[39,51,58,67],[45,52,58,61]]):
    t=40+j*3
    opening.chord(t,chord[1:],2.85,velocity=42+j*4)
    opening.note(t,chord[0],2.8,CELLO,55)
    for k in range(4): opening.note(t+k*.75,chord[1]+(7 if k%2 else 0),.35,PIZZ,47+j*5)
    opening.note(t+1.5,77+j,1.25,STRINGS,34+j*4)
opening.chord(49,[50,57,64],3.7,velocity=28)
opening.phrase(49.5,[(74,1),(77,1),(76,2)],.7,PIANO,47)
# Curse / separation: the warm motif loses notes, then falls through the register.
for j,chord in enumerate([[50,57,65,68],[46,53,58,64],[43,50,58,61],[45,52,58,61]]):
    t=53+j*2
    opening.chord(t,chord,1.9,velocity=40+j*3)
    opening.note(t,chord[0]-12,1.85,CELLO,49)
    opening.phrase(t+.25,[(chord[-1]+12,.5),(chord[-2]+12,.5),(chord[1],1)],.65,CELESTA,42)
opening.chord(61,[50,57,65],4.6,velocity=30)
opening.phrase(61.5,[(77,1),(81,1),(None,1),(76,1)],1,PIANO,51)
for j,chord in enumerate([[50,57,65],[46,53,64],[45,52,61]]):
    t=66+j*2
    opening.chord(t,chord,1.9,velocity=42+j*5)
    opening.note(t,chord[0]-12,1.9,CELLO,50+j*4)
    for k in range(4): opening.note(t+k*.4,chord[k%3]+12,.7,HARP,48+k*2)
opening.chord(72,[38,50,57,65],2.5,velocity=54)
opening.phrase(73,[(81,.5),(77,.5),(74,.5),(69,1),(65,1)],.8,PIANO,65)
opening.chord(75.5,[46,53,57,62],3.1,velocity=31)
opening.phrase(76,[(74,1),(77,1),(76,1)],.75,CELESTA,42)
opening.chord(79,[50,57,64],3.2,velocity=24)
opening.note(79.5,69,2.2,PIANO,47)
opening.chord(82.5,[50,57,64,65],5.5,velocity=26)
opening.phrase(82.8,[(74,1),(77,1),(81,1),(76,1),(None,1),(74,1)],.85,PIANO,49)
opening.write("opening_story")

# 24 bars in 3/4 at 80 bpm: a 54-second exploration loop with breathing space.
room = Score(54)
minor_chords=[[50,57,64,65],[46,53,57,62],[53,57,60,64],[48,55,62,64],
              [43,50,57,58],[46,53,57,62],[45,52,55,62],[45,52,55,61]]
minor_melodies=[[(74,1),(77,1),(81,1)],[(77,2),(74,1)],[(76,1),(72,2)],[(74,1),(76,1),(None,1)],
                [(74,1),(70,1),(69,1)],[(65,2),(69,1)],[(67,1),(64,1),(None,1)],[(73,1),(69,1),(None,1)]]
for j in range(24):
    t=j*2.25
    chord=minor_chords[j%8]
    room.chord(t,chord,2.05,velocity=24)
    for k,pitch in enumerate([chord[0],chord[2],chord[1]]):
        room.note(t+k*.75,pitch,.95,HARP,38+(k%2)*5)
    if j%8 < 7:
        notes=minor_melodies[j%8]
        if j>=16: notes=[(p-12 if p else None,b) for p,b in notes]
        room.phrase(t+.06,notes,.75,PIANO,46 if j<16 else 44)
    if j in [2,10,18]: room.note(t+.8,81,1.4,CELESTA,32)
room.write("hollow_morning")
print("SCORES_COMPOSED opening=88.5s exploration=54s")
