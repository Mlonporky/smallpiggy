"""Validate PCM source seams and actual Godot mixer captures (standard library)."""
import array
import hashlib
import json
import math
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/audio/phase5_2026-10-31"


def read(path):
    with wave.open(str(path), "rb") as f:
        assert f.getsampwidth() == 2 and f.getcomptype() == "NONE", path
        channels, rate, frames = f.getnchannels(), f.getframerate(), f.getnframes()
        samples = array.array("h", f.readframes(frames))
    if sys.byteorder != "little": samples.byteswap()
    peak = max(abs(x) for x in samples)
    rms = math.sqrt(sum(x * x for x in samples) / len(samples))
    return samples, {"seconds": frames / rate, "rate": rate, "channels": channels,
                     "peak_dbfs": 20 * math.log10(max(peak, 1) / 32768),
                     "rms_dbfs": 20 * math.log10(max(rms, 1e-9) / 32768),
                     "peak_pcm": peak, "clipped_samples": sum(abs(x) >= 32767 for x in samples),
                     "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    sources = {}
    for path in sorted((ROOT / "assets/audio/gameplay_v1").glob("*.wav")):
        data, stats = read(path)
        assert stats["rate"] == 22050 and stats["clipped_samples"] == 0
        channels = stats["channels"]
        edge = max(abs(data[c] - data[-channels + c]) for c in range(channels))
        assert edge == 0, (path, "nonzero PCM seam/endpoints", edge)
        stats["edge_delta_pcm"] = edge
        if path.stem in ["forest_air", "forest_leaves", "cave_air"]:
            window = stats["rate"] * channels // 10
            edge_rms = math.sqrt(sum(x*x for x in data[-window:]) / window) / 32768
            assert edge_rms > .001, (path, "silent loop gap")
            stats["last_100ms_rms"] = edge_rms
        sources[path.stem] = stats
    assert len(sources) == 26
    mixes = {}
    for name in ["ambience", "ambience_off", "effect", "effects_off", "muted", "local_paused", "settings_paused", "resumed", "menu"]:
        _, stats = read(OUT / ("mix_" + name + ".wav"))
        assert stats["clipped_samples"] == 0
        if name in ["ambience_off", "effects_off", "muted", "local_paused", "settings_paused", "menu"]:
            assert stats["peak_pcm"] <= 1, (name, "not silent", stats)
        else:
            assert stats["rms_dbfs"] > -65, (name, "expected audible signal", stats)
        mixes[name] = stats
    samples, sample = read(OUT / "gameplay_audio_sample.wav")
    assert 31.8 < sample["seconds"] < 32.8 and sample["clipped_samples"] == 0
    assert -60 < sample["rms_dbfs"] < -15 and sample["peak_dbfs"] < -6
    events = json.loads((OUT / "playback_events.json").read_text())
    expected = ["step_1", "step_2", "step_3", "wood_pickup", "jump", "land",
                "step_2", "step_1", "swing", "hit", "purify", "gift",
                "jump", "land", "bounce", "chime", "chime", "chime", "crack", "equip",
                "paper", "paper", "paper", "paper", "complete"]
    assert [e["kind"] for e in events["events"]] == expected
    assert events["state_unchanged"]
    # A clearly labelled louder copy is easier to audition outside the game.
    # Keep the original engine recording untouched as the mix evidence.
    listen = array.array("h", (round(x * 10 ** (12 / 20)) for x in samples))
    assert max(abs(x) for x in listen) < 32767
    if sys.byteorder != "little": listen.byteswap()
    with wave.open(str(OUT / "gameplay_audio_listen.wav"), "wb") as f:
        f.setnchannels(sample["channels"])
        f.setsampwidth(2)
        f.setframerate(sample["rate"])
        f.writeframes(listen.tobytes())
    _, listen_stats = read(OUT / "gameplay_audio_listen.wav")
    result = {"source_files": sources, "mixer_checks": mixes, "sample": sample,
              "listening_copy": {"gain_db": 12, **listen_stats},
              "events": len(expected), "passed": True,
              "scope": "PCM and mixer evidence only; listening quality remains for user review."}
    (OUT / "validation.json").write_text(json.dumps(result, indent=2) + "\n")
    print("GAMEPLAY_AUDIO_VALIDATION_OK sources=26 mixer_checks=9 sample_events=25")
    print(json.dumps({"sample": sample, "silent_captures": {k:v["peak_pcm"] for k,v in mixes.items() if k not in ["ambience", "effect", "resumed"]}}, indent=2))


if __name__ == "__main__": main()
