"""Original deterministic synthesized foley/ambience; no recordings or downloads.

Run with Python's standard library. Runtime only loads the resulting PCM WAVs.
"""
import array
import json
import math
import random
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/audio/gameplay_v1"
RATE = 22050
TAU = math.tau
REPORT = {}


def filtered_noise(count, seed, low=0.04, high=0.3):
    rng = random.Random(seed)
    slow = fast = 0.0
    result = []
    for _ in range(count):
        white = rng.uniform(-1, 1)
        slow += low * (white - slow)
        fast += high * (white - fast)
        result.append(fast - slow)
    return result


def bell(t, hz, decay=7):
    return (math.sin(TAU * hz * t) + 0.22 * math.sin(TAU * hz * 2.71 * t)
            + 0.08 * math.sin(TAU * hz * 4.13 * t)) * math.exp(-t * decay)


def envelope(t, length, attack=0.008):
    return min(1, t / attack) * min(1, (length - t) / 0.045)


def write(name, channels, loop=False, peak=0.48):
    count = len(channels[0])
    maximum = max(abs(v) for c in channels for v in c)
    gain = peak / max(maximum, 1e-9)
    pcm = array.array("h")
    squares = 0.0
    clipped = 0
    for i in range(count):
        for c in channels:
            value = c[i] * gain
            if not loop:
                value *= min(1, i / 90, (count - 1 - i) / 220)
            integer = round(value * 32767)
            assert -32767 < integer < 32767
            squares += (integer / 32768) ** 2
            clipped += abs(integer) >= 32767
            pcm.append(integer)
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / (name + ".wav")), "wb") as f:
        f.setnchannels(len(channels))
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())
    edge = max(abs(pcm[c] - pcm[-len(channels) + c]) for c in range(len(channels)))
    REPORT[name] = {"seconds": count / RATE, "channels": len(channels), "rate": RATE,
                    "loop": loop, "peak_dbfs": 20 * math.log10(max(abs(v) for v in pcm) / 32768),
                    "rms_dbfs": 20 * math.log10(math.sqrt(squares / len(pcm))),
                    "clipped_samples": clipped, "edge_delta_pcm": edge}


def ambience(name, seconds, seed, leaves=False, cave=False):
    n = RATE * seconds
    overlap = RATE
    channels = []
    for channel in range(2):
        air = filtered_noise(n + overlap, seed + channel, .0008 if cave else .002,
                             .028 if cave else (.36 if leaves else .06))
        for i in range(len(air)):
            t = i / RATE
            swell = .62 + .18 * math.sin(TAU * t / 11.7 + channel * .8) + .13 * math.sin(TAU * t / 4.9)
            air[i] *= swell * (.55 + .45 * math.sin(t * 1.2) ** 4 if leaves else 1)
        # Overlap one second of continuous source at the wrap, no silent loop gap.
        x = air[:n]
        for i in range(overlap):
            a = .5 - .5 * math.cos(math.pi * i / (overlap - 1))
            x[i] = air[n + i] * (1 - a) + air[i] * a
        if cave:
            # Sparse, soft water resonances with unequal echo spacing.
            for at in [2.4, 8.7, 14.1, 18.3]:
                for echo, strength in [(0, .018), (.117, .006), (.281, .003)]:
                    for j in range(int(.38 * RATE)):
                        t = j / RATE
                        index = int((at + echo + channel * .021) * RATE) + j
                        if index < n:
                            x[index] += strength * bell(t, 910 + channel * 81, 19) * min(1, t * 500)
        # A tiny boundary correction makes the PCM seam exact without a fade to silence.
        delta = x[-1] - x[0]
        for i in range(100):
            x[i] += delta * (.5 + .5 * math.cos(math.pi * i / 99))
        channels.append(x)
    write(name, channels, loop=True, peak=.28)


def foley(name, length, seed, style):
    n = int(length * RATE)
    grain = filtered_noise(n, seed, .025, .5)
    low = filtered_noise(n, seed + 500, .002, .065)
    x = []
    for i in range(n):
        t = i / RATE
        u = t / length
        v = 0.0
        if style in ["step", "land", "hit"]:
            decay = 26 if style == "step" else (18 if style == "land" else 30)
            hz = 98 if style != "hit" else 76
            v = (low[i] * 2.1 + grain[i] * .22 + .11 * math.sin(TAU * hz * t)) * math.exp(-decay * t)
            v += grain[i] * .13 * math.exp(-((t - .085) / .038) ** 2)
        elif style in ["paper", "wood", "crack", "equip"]:
            for at, weight in [(.014, 1.0), (.052, .65), (.113, .38), (.178, .22)]:
                age = t - at
                if age >= 0:
                    v += grain[i] * weight * math.exp(-age * (32 if style == "paper" else 100))
                    if style != "paper":
                        v += .12 * math.sin(TAU * (370 if style == "wood" else 210) * age) * weight * math.exp(-age * 70)
        elif style in ["swing", "roll", "puff", "swoop", "drop", "jump"]:
            v = (grain[i] * (.3 if style == "roll" else .8) + low[i] * 1.8) * math.sin(math.pi * u) ** 2
            if style == "roll": v *= .65 + .35 * math.sin(t * 71) ** 2
            if style in ["jump", "drop"]:
                phase = TAU * (150 * t + (240 if style == "jump" else -90) * t * t)
                v += .035 * math.sin(phase) * math.sin(math.pi * u) ** 2
        elif style == "bounce":
            v = .22 * math.sin(TAU * (125 * t + 390 * t * t)) * math.exp(-t * 8)
            v += .35 * low[i] * math.exp(-t * 24)
        elif style == "clang":
            for hz, amp in [(870, .16), (1447, .09), (2331, .035)]:
                v += amp * math.sin(TAU * hz * t) * math.exp(-t * (7 + hz / 140))
            v += grain[i] * .15 * math.exp(-t * 70)
        elif style == "alert":
            v = .16 * bell(t, 622, 14)
            if t > .12: v += .10 * bell(t - .12, 740, 18)
        else:
            notes = [(0, 784)] if style == "chime" else [(0, 523.25), (.10, 659.25), (.21, 783.99)]
            if style == "complete": notes.append((.32, 1046.5))
            for at, hz in notes:
                age = t - at
                if age >= 0: v += .14 * bell(age, hz, 7) * min(1, age * 220)
            if style == "gift": v += grain[i] * .45 * math.exp(-t * 23)
        x.append(v * envelope(t, length))
    write(name, [x])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    ambience("forest_air", 24, 5101)
    ambience("forest_leaves", 24, 5201, leaves=True)
    ambience("cave_air", 20, 5301, cave=True)
    specs = [("step_1", .28, "step"), ("step_2", .30, "step"), ("step_3", .27, "step"),
             ("land", .36, "land"), ("hit", .25, "hit"), ("swing", .26, "swing"),
             ("wood_pickup", .32, "wood"), ("paper", .36, "paper"), ("gift", .80, "gift"),
             ("equip", .33, "equip"), ("crack", .43, "crack"), ("bounce", .38, "bounce"),
             ("chime", .52, "chime"), ("heal", .86, "heal"), ("purify", .92, "purify"),
             ("complete", 1.05, "complete"), ("alert", .30, "alert"), ("roll", .42, "roll"),
             ("puff", .32, "puff"), ("swoop", .42, "swoop"), ("drop", .30, "drop"),
             ("clang", .48, "clang"), ("jump", .24, "jump")]
    for i, (name, length, style) in enumerate(specs): foley(name, length, 6000 + i, style)
    report = ROOT / "docs/audio/phase5_2026-10-31"
    report.mkdir(parents=True, exist_ok=True)
    (report / "source_validation.json").write_text(json.dumps(REPORT, indent=2) + "\n")
    print("GAMEPLAY_AUDIO_RENDER_OK assets=" + str(len(REPORT)))


if __name__ == "__main__": main()
