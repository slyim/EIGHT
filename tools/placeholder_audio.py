"""EIGHT placeholder audio generator.

Every sound produced here is a temporary PLACEHOLDER AUDIO file synthesized by code,
to be replaced by human-made audio. Standard library only; ffmpeg (on PATH) encodes
the music loop to Ogg Vorbis.

Usage (from the repository root):
    python tools/placeholder_audio.py eight/assets/audio/placeholder
"""

import math
import os
import random
import struct
import subprocess
import sys
import wave

RATE = 44100


def buffer(seconds: float) -> list[float]:
    return [0.0] * int(seconds * RATE)


def envelope(i: int, n: int, attack: float, release: float) -> float:
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    remaining = (n - i) / RATE
    r = min(1.0, remaining / release) if release > 0 else 1.0
    return a * r


def osc(kind: str, phase: float) -> float:
    p = phase % 1.0
    if kind == "sine":
        return math.sin(phase * math.tau)
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if p < 0.25 else -1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    raise ValueError(kind)


def tone(out, start, seconds, f0, f1=None, kind="sine", gain=0.5, attack=0.005,
         release=0.05, cutoff=None, curve=1.0, detune=0.0):
    """Add a pitched note, optionally sweeping f0 -> f1, through a one-pole lowpass."""
    f1 = f0 if f1 is None else f1
    n = int(seconds * RATE)
    offset = int(start * RATE)
    phase = phase2 = 0.0
    low = 0.0
    alpha = None if cutoff is None else 1.0 - math.exp(-math.tau * cutoff / RATE)
    for i in range(n):
        if offset + i >= len(out):
            break
        k = (i / n) ** curve
        f = f0 + (f1 - f0) * k
        phase += f / RATE
        s = osc(kind, phase)
        if detune:
            phase2 += f * (1.0 + detune) / RATE
            s = 0.5 * (s + osc(kind, phase2))
        if alpha is not None:
            low += alpha * (s - low)
            s = low
        out[offset + i] += s * gain * envelope(i, n, attack, release)


def noise(out, start, seconds, gain=0.4, cutoff0=4000.0, cutoff1=None, attack=0.002,
          release=0.05, seed=1):
    """Add filtered white noise with a sweeping lowpass cutoff."""
    rng = random.Random(seed)
    cutoff1 = cutoff0 if cutoff1 is None else cutoff1
    n = int(seconds * RATE)
    offset = int(start * RATE)
    low = 0.0
    for i in range(n):
        if offset + i >= len(out):
            break
        c = cutoff0 + (cutoff1 - cutoff0) * i / n
        alpha = 1.0 - math.exp(-math.tau * c / RATE)
        low += alpha * (rng.uniform(-1.0, 1.0) - low)
        out[offset + i] += low * gain * envelope(i, n, attack, release)


def note(name: str) -> float:
    names = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
             "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12 - 9) / 12)


def write_wav(path: str, data: list[float], peak: float = 0.85) -> None:
    top = max(1e-9, max(abs(s) for s in data))
    scale = peak / top
    frames = bytearray()
    for s in data:
        v = math.tanh(s * scale * 1.1) / math.tanh(1.1)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))


# --------------------------------------------------------------------------
# Sound effects
# --------------------------------------------------------------------------

def sfx() -> dict[str, list[float]]:
    sounds: dict[str, list[float]] = {}

    s = buffer(0.2)
    noise(s, 0, 0.18, 0.6, 6000, 600, release=0.12)
    tone(s, 0, 0.12, 320, 140, "tri", 0.35, release=0.08)
    sounds["spear_thrust"] = s

    s = buffer(0.45)
    noise(s, 0, 0.3, 0.55, 9000, 900, attack=0.02, release=0.2, seed=11)
    tone(s, 0, 0.35, 900, 300, "tri", 0.25, release=0.2)
    for i, name in enumerate(["A5", "E6"]):
        tone(s, 0.05 + i * 0.05, 0.3, note(name), kind="sine", gain=0.15, release=0.25)
    sounds["spear_sweep"] = s

    s = buffer(0.3)
    noise(s, 0, 0.25, 0.35, 800, 5000, attack=0.02, release=0.15, seed=12)
    tone(s, 0, 0.22, 260, 520, "sine", 0.25, release=0.12)
    sounds["jump"] = s

    s = buffer(0.3)
    tone(s, 0, 0.25, 110, 45, "sine", 0.9, release=0.15)
    noise(s, 0, 0.18, 0.4, 1800, 200, release=0.12, seed=13)
    sounds["land"] = s

    s = buffer(2.8)
    for i, name in enumerate(["D4", "A4", "D5", "F#5", "A5"]):
        tone(s, 0.1 + i * 0.06, 2.4, note(name), kind="tri", gain=0.16, attack=0.05, release=1.6)
    tone(s, 0, 0.8, 90, 30, "sine", 1.0, release=0.5)
    noise(s, 0, 1.4, 0.5, 3000, 100, release=1.0, seed=14)
    sounds["holy_land"] = s

    s = buffer(0.12)
    noise(s, 0, 0.05, 0.6, 5000, 1500, release=0.04, seed=2)
    tone(s, 0, 0.1, 200, 70, "sine", 0.8, release=0.06)
    sounds["enemy_hit"] = s

    s = buffer(0.3)
    tone(s, 0, 0.26, 420, 70, "square", 0.35, cutoff=1800, release=0.15, curve=0.6)
    noise(s, 0.02, 0.22, 0.35, 2500, 300, release=0.15, seed=3)
    sounds["enemy_death"] = s

    s = buffer(0.4)
    tone(s, 0, 0.35, 140, 45, "sine", 0.9, release=0.2)
    tone(s, 0, 0.25, 260, 110, "square", 0.25, cutoff=1400, release=0.15)
    noise(s, 0, 0.2, 0.45, 3500, 500, release=0.12, seed=4)
    sounds["player_hurt"] = s

    s = buffer(0.25)
    noise(s, 0, 0.22, 0.6, 500, 7000, attack=0.03, release=0.12, seed=5)
    tone(s, 0, 0.18, 300, 700, "sine", 0.15, release=0.1)
    sounds["dash"] = s

    s = buffer(0.09)
    tone(s, 0, 0.08, 1100, 1650, "square", 0.25, cutoff=5000, release=0.05)
    sounds["pickup_xp"] = s

    s = buffer(0.45)
    tone(s, 0, 0.2, note("A5"), kind="tri", gain=0.5, release=0.15)
    tone(s, 0.1, 0.32, note("E6"), kind="tri", gain=0.45, release=0.25)
    sounds["pickup_life"] = s

    s = buffer(0.8)
    for i, name in enumerate(["D5", "F5", "A5", "D6", "F6"]):
        tone(s, i * 0.07, 0.35, note(name), kind="tri", gain=0.4, release=0.25)
        tone(s, i * 0.07 + 0.18, 0.3, note(name), kind="tri", gain=0.12, release=0.2)
    sounds["pickup_item"] = s

    s = buffer(1.0)
    for i, name in enumerate(["D4", "F4", "A4", "C5", "D5", "A5"]):
        tone(s, i * 0.08, 0.5, note(name), kind="square", gain=0.18, cutoff=3000, release=0.35)
    tone(s, 0.45, 0.5, note("D6"), kind="tri", gain=0.35, release=0.4)
    sounds["level_up"] = s

    s = buffer(2.6)
    for f, det in ((note("D1"), 0.006), (note("A1"), 0.004), (note("Eb2"), 0.007)):
        tone(s, 0, 2.5, f, f * 0.97, "saw", 0.3, attack=0.8, release=0.9, cutoff=400, detune=det)
    noise(s, 0, 2.4, 0.35, 150, 900, attack=1.2, release=0.6, seed=6)
    sounds["boss_spawn"] = s

    s = buffer(0.45)
    tone(s, 0, 0.4, 95, 55, "saw", 0.6, cutoff=700, release=0.2, detune=0.01)
    noise(s, 0, 0.3, 0.3, 1200, 200, release=0.2, seed=7)
    sounds["boss_attack"] = s

    s = buffer(2.4)
    tone(s, 0, 2.2, 220, 30, "saw", 0.5, cutoff=900, release=1.0, curve=0.5, detune=0.01)
    noise(s, 0, 2.0, 0.5, 2000, 80, release=1.2, seed=8)
    tone(s, 0, 0.6, 70, 35, "sine", 0.9, release=0.4)
    sounds["boss_death"] = s

    s = buffer(3.0)
    for i, name in enumerate(["D4", "F#4", "A4", "D5", "F#5", "A5"]):
        tone(s, i * 0.12, 2.6 - i * 0.12, note(name), kind="tri", gain=0.25, attack=0.02, release=1.5)
    sounds["victory"] = s

    s = buffer(2.6)
    for i, name in enumerate(["A4", "F4", "D4", "A3"]):
        tone(s, i * 0.35, 1.2, note(name), kind="square", gain=0.18, cutoff=1500, release=0.8)
    tone(s, 1.2, 1.3, note("D2"), kind="saw", gain=0.35, cutoff=500, release=1.0)
    sounds["defeat"] = s

    return sounds


# --------------------------------------------------------------------------
# Music loop: dark synth in D Phrygian-minor, 110 BPM, 16 bars.
# --------------------------------------------------------------------------

def music() -> list[float]:
    bpm = 110
    beat = 60.0 / bpm
    bars = 16
    out = buffer(bars * 4 * beat)
    progression = [
        ("D2", ["D4", "F4", "A4"]), ("Bb1", ["Bb3", "D4", "F4"]),
        ("G1", ["G3", "Bb3", "D4"]), ("A1", ["A3", "C#4", "E4"]),
    ]
    for bar in range(bars):
        root, chord = progression[bar % 4]
        t0 = bar * 4 * beat
        # Pad
        for name in chord:
            tone(out, t0, 4 * beat, note(name), kind="saw", gain=0.05, attack=0.6, release=0.6,
                 cutoff=900, detune=0.005)
        # Bass: driving eighths with an octave skip
        for step in range(8):
            f = note(root) * (2 if step in (3, 7) else 1)
            tone(out, t0 + step * beat / 2, beat / 2 * 0.9, f, kind="saw", gain=0.22,
                 attack=0.003, release=0.05, cutoff=600)
        # Drums
        for b in range(4):
            tb = t0 + b * beat
            if b in (0, 2) or (b == 3 and bar % 2 == 1):
                tone(out, tb, 0.25, 120, 40, "sine", 0.7, release=0.15, curve=0.4)
            if b in (1, 3):
                noise(out, tb, 0.18, 0.3, 4000, 1500, release=0.12, seed=bar * 4 + b)
            for half in (0, 1):
                noise(out, tb + half * beat / 2, 0.04, 0.08, 9000, 7000, release=0.03,
                      seed=100 + bar * 8 + b * 2 + half)
        # Arpeggio from bar 5
        if bar >= 4:
            arp = [chord[0], chord[1], chord[2], chord[1]]
            for step in range(16):
                name = arp[step % 4]
                f = note(name) * (2 if (step // 4) % 2 == 1 and bar >= 8 else 1) * 2
                tone(out, t0 + step * beat / 4, beat / 4 * 0.6, f, kind="pulse", gain=0.06,
                     attack=0.002, release=0.04, cutoff=3500)
    return out


def main() -> None:
    folder = sys.argv[1] if len(sys.argv) > 1 else "eight/assets/audio/placeholder"
    os.makedirs(folder, exist_ok=True)
    for name, data in sfx().items():
        write_wav(os.path.join(folder, f"placeholder_{name}.wav"), data)
    temp = os.path.join(folder, "_music_temp.wav")
    write_wav(temp, music(), peak=0.7)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", temp, "-c:a", "libvorbis",
                    "-q:a", "5", os.path.join(folder, "placeholder_music_loop.ogg")], check=True)
    os.remove(temp)


if __name__ == "__main__":
    main()
