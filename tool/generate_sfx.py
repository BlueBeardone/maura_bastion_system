#!/usr/bin/env python3
"""Generate the synthesized SFX palette under assets/sfx/.

Run once from repo root:  python3 tool/generate_sfx.py
All clips are mono, 22050 Hz, 16-bit WAV, a few KB each.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path("assets/sfx")
OUT.mkdir(parents=True, exist_ok=True)
random.seed(42)


def write(name, samples):
    with wave.open(str(OUT / name), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples))


def env(t, attack, decay):
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def tone(freq, dur, decay, vol=0.6):
    n = int(dur * RATE)
    return [vol * env(i / RATE, 0.002, decay) *
            math.sin(2 * math.pi * freq * i / RATE) for i in range(n)]


def noise(dur, decay, vol=0.5):
    n = int(dur * RATE)
    return [vol * env(i / RATE, 0.001, decay) *
            (random.random() * 2 - 1) for i in range(n)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


def silence(dur):
    return [0.0] * int(dur * RATE)


# dice clatter: five short decaying noise ticks
dice = []
for i in range(5):
    dice += noise(0.05, 0.012, vol=0.5) + silence(0.05 + 0.02 * i)
write("dice_clatter.wav", dice)

# coin clink: two bright pings plus an echo ping
write("coin_clink.wav", mix(
    tone(2500, 0.25, 0.06, vol=0.4),
    tone(3720, 0.2, 0.04, vol=0.3),
    silence(0.09) + tone(2900, 0.18, 0.05, vol=0.35)))

# stamp thunk: low thump plus a paper slap
write("stamp_thunk.wav", mix(tone(85, 0.3, 0.05, vol=0.8),
                             noise(0.06, 0.008, vol=0.25)))

# quill scratch: amplitude-wobbled noise
scratch = [
    0.45 * env(i / RATE, 0.01, 0.05) * (random.random() * 2 - 1) *
    (0.6 + 0.4 * math.sin(2 * math.pi * 14 * i / RATE))
    for i in range(int(0.45 * RATE))]
write("quill_scratch.wav", scratch)

# page turn: single noise swell up then down
turn = [
    0.5 * (random.random() * 2 - 1) * math.sin(math.pi * i / (int(0.6 * RATE) - 1))
    for i in range(int(0.6 * RATE))]
write("page_turn.wav", turn)

# fanfare: rising three-note arpeggio
fanfare = silence(0.02)
for freq, dur in ((523.25, 0.16), (659.25, 0.16), (783.99, 0.45)):
    fanfare += tone(freq, dur, 0.09 if dur < 0.3 else 0.2, vol=0.45)
write("fanfare.wav", fanfare)