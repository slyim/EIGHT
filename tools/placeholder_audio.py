"""Synthesize EIGHT's prototype audio with Python and ffmpeg from the repository root.

    python tools/placeholder_audio.py eight/assets/audio/placeholder
"""

from array import array
import math
from pathlib import Path
import random
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave

RATE = 44100
STEP = math.tau / RATE
MUSIC_SECONDS = 72


def buffer(seconds):
    return array("f", [0.0]) * round(seconds * RATE)


def envelope(i, n, attack, release):
    fade = min(1.0, i / attack, (n - 1 - i) / release)
    return fade * fade * (3.0 - 2.0 * fade)


def pitch(semitones):
    """Pitch in semitones above D4."""
    return 293.6647679 * 2 ** (semitones / 12)


def tone(out, start, length, f0, f1, gain, attack=0.003, release=0.08, drive=0.0):
    """Exponential pitch sweep, optionally with soft saturation for a growl."""
    offset = round(start * RATE)
    n = round(length * RATE)
    attack *= RATE
    release *= RATE
    phase = 0.0
    step = f0 * STEP
    glide = (f1 / f0) ** (1.0 / n)
    for i in range(n):
        value = math.sin(phase)
        if drive:
            value = math.tanh(drive * (value + 0.22 * math.sin(phase * 2)))
        out[offset + i] += gain * value * envelope(i, n, attack, release)
        phase += step
        step *= glide


def air(out, start, length, f0, f1, gain, *, attack, release, seed):
    """Sweep a noise band with an independent envelope for breath, grit or impact."""
    rng = random.Random(seed)
    offset = round(start * RATE)
    n = round(length * RATE)
    attack *= RATE
    release *= RATE
    upper = math.exp(-2.0 * f0 * STEP)
    lower = math.exp(-0.5 * f0 * STEP)
    upper_end = math.exp(-2.0 * f1 * STEP)
    lower_end = math.exp(-0.5 * f1 * STEP)
    upper_step = (upper_end - upper) / n
    lower_step = (lower_end - lower) / n
    fast = slow = 0.0
    for i in range(n):
        sample = 2.0 * rng.random() - 1.0
        fast = sample + upper * (fast - sample)
        slow = sample + lower * (slow - sample)
        out[offset + i] += gain * (fast - slow) * envelope(i, n, attack, release)
        upper += upper_step
        lower += lower_step


def bell(out, start, length, semitones, gain, metal=0.5):
    """A mallet fundamental with inharmonic modes that decay faster than the note."""
    f = pitch(semitones)
    n = round(length * RATE)
    offset = round(start * RATE)
    modes = ((1.0, 1.0, 2.7), (2.01, 0.20, 4.7),
             (2.76, metal * 0.32, 8.1), (4.08, metal * 0.15, 10.6))
    for ratio, weight, decay in modes:
        step = f * ratio * STEP
        fall = math.exp(-decay / n)
        level = gain * weight
        for i in range(n):
            out[offset + i] += level * math.sin(step * i) * envelope(i, n, 160, n * 0.2)
            level *= fall


def choir(out, start, length, semitones, gain, *, attack, release):
    """Vowel-shaped harmonics and a second, loosely tuned voice."""
    f = pitch(semitones)
    step = f * STEP
    n = round(length * RATE)
    offset = round(start * RATE)
    attack *= RATE
    release *= RATE
    weights = []
    for harmonic in range(1, 8):
        hz = f * harmonic
        # Broad ah/oo formants suppress brittle upper harmonics.
        weight = 0.65 * math.exp(-((hz - 520) / 310) ** 2)
        weight += 0.22 * math.exp(-((hz - 1060) / 300) ** 2)
        weights.append((weight + 0.08) / harmonic)
    for i in range(n):
        phase = step * i + 0.24 * math.sin(4.2 * STEP * i)
        double = step * 1.0027 * i + 0.16 * math.sin(4.9 * STEP * i + 1.8)
        voice = 0.60 * math.sin(double) + 0.20 * math.sin(2 * double)
        for harmonic, weight in enumerate(weights, 1):
            voice += weight * math.sin(harmonic * phase)
        out[offset + i] += gain * voice * envelope(i, n, attack, release)


def space(dry, taps, *, wrap=False):
    """Mix quiet, uneven reflections, wrapping tails only for the music bed."""
    wet = dry[:]
    for delay, gain in taps:
        shift = round(delay * RATE)
        for i in range(shift, len(dry)):
            wet[i] += dry[i - shift] * gain
        if wrap:
            for i in range(shift):
                wet[i] += dry[i - shift] * gain
    return wet


def sfx():
    sound = buffer(0.17)
    air(sound, 0.0, 0.13, 3800, 760, 0.70, attack=0.009, release=0.092, seed=1)
    tone(sound, 0.006, 0.075, 610, 155, 0.20, release=0.06)
    bell(sound, 0.01, 0.12, 12, 0.09, metal=0.95)
    yield "spear_thrust", sound, -25, -13

    sound = buffer(0.34)
    air(sound, 0.0, 0.25, 900, 2300, 0.76, attack=0.045, release=0.16, seed=11)
    air(sound, 0.04, 0.16, 3600, 500, 0.50, attack=0.015, release=0.125, seed=31)
    tone(sound, 0.035, 0.15, 318, 105, 0.20, release=0.12)
    bell(sound, 0.064, 0.24, 14, 0.17, metal=0.95)
    yield "spear_sweep", sound, -23, -10

    sound = buffer(0.26)
    air(sound, 0, 0.24, 230, 2350, 0.78, attack=0.048, release=0.14, seed=5)
    air(sound, 0.042, 0.14, 1500, 600, 0.27, attack=0.009, release=0.11, seed=15)
    tone(sound, 0.027, 0.16, 116, 350, 0.18, attack=0.018, release=0.13)
    yield "dash", sound, -23, -10

    sound = buffer(0.26)
    air(sound, 0.0, 0.18, 2800, 1150, 0.38, attack=0.036, release=0.115, seed=12)
    tone(sound, 0.01, 0.16, 185, 390, 0.09, attack=0.027, release=0.12)
    bell(sound, 0.06, 0.18, 7, 0.08, metal=0.12)
    yield "jump", sound, -25, -13

    sound = buffer(0.23)
    air(sound, 0, 0.032, 2200, 750, 0.67, attack=0.0015, release=0.027, seed=13)
    tone(sound, 0, 0.12, 121, 49, 0.62, release=0.1, drive=1.1)
    air(sound, 0.019, 0.16, 780, 180, 0.39, attack=0.008, release=0.129, seed=23)
    yield "land", sound, -24, -11

    sound = buffer(2.75)
    tone(sound, 0, 0.46, 105, 37, 0.62, release=0.39)
    air(sound, 0, 0.75, 1400, 170, 0.69, attack=0.008, release=0.68, seed=14)
    for i, degree in enumerate((-12, -5, 0, 7)):
        choir(sound, 0.06 + i * 0.071, 2.03, degree, 0.19, attack=0.32, release=1.25)
    bell(sound, 0.14, 1.6, 0, 0.23, metal=0.32)
    bell(sound, 0.33, 1.45, 12, 0.14, metal=0.32)
    yield "holy_land", space(sound, ((0.053, 0.20), (0.113, 0.15), (0.237, 0.09))), -20, -6

    sound = buffer(0.12)
    air(sound, 0, 0.023, 3400, 1750, 0.81, attack=0.0015, release=0.02, seed=2)
    tone(sound, 0, 0.083, 206, 73, 0.61, release=0.075, drive=1.4)
    air(sound, 0.011, 0.076, 1000, 370, 0.31, attack=0.004, release=0.062, seed=22)
    yield "enemy_hit", sound, -24, -11

    sound = buffer(0.27)
    air(sound, 0, 0.046, 2400, 720, 0.93, attack=0.002, release=0.038, seed=3)
    tone(sound, 0.006, 0.16, 185, 43, 0.37, release=0.135, drive=1.8)
    air(sound, 0.041, 0.19, 1050, 220, 0.46, attack=0.012, release=0.16, seed=33)
    yield "enemy_death", sound, -25, -11

    sound = buffer(0.39)
    air(sound, 0, 0.054, 3100, 440, 0.82, attack=0.0015, release=0.043, seed=4)
    tone(sound, 0.005, 0.23, 110, 48, 0.56, release=0.17, drive=1.6)
    tone(sound, 0.015, 0.23, 330, 143, 0.30, attack=0.008, release=0.14, drive=1.15)
    air(sound, 0.055, 0.25, 960, 220, 0.48, attack=0.025, release=0.185, seed=44)
    yield "player_hurt", sound, -19, -7

    sound = buffer(0.108)
    bell(sound, 0, 0.095, 12, 0.58, metal=0.10)
    bell(sound, 0.026, 0.077, 19, 0.31, metal=0.10)
    yield "pickup_xp", sound, -29, -17

    sound = buffer(0.49)
    bell(sound, 0, 0.29, 2, 0.46, metal=0.19)
    bell(sound, 0.09, 0.323, 7, 0.47, metal=0.20)
    yield "pickup_life", space(sound, ((0.047, 0.17), (0.07, 0.10))), -22, -9

    sound = buffer(0.75)
    for start, degree, gain in ((0, 0, 0.42), (0.073, 7, 0.38), (0.157, 12, 0.37)):
        bell(sound, start, 0.47, degree, gain, metal=0.38)
    yield "pickup_item", space(sound, ((0.051, 0.22), (0.119, 0.12))), -21, -8

    sound = buffer(1.35)
    for i, degree in enumerate((0, 5, 7, 12, 16)):
        bell(sound, i * 0.095, 0.74, degree, 0.34, metal=0.30)
    for degree in (-12, -5, 0):
        choir(sound, 0.12, 1.04, degree, 0.16, attack=0.16, release=0.66)
    yield "level_up", space(sound, ((0.057, 0.21), (0.146, 0.12))), -19, -7

    sound = buffer(2.55)
    tone(sound, 0, 2.28, 38, 48, 0.48, attack=0.64, release=0.90)
    tone(sound, 0.11, 1.9, 56, 125, 0.27, attack=0.73, release=0.66, drive=2.5)
    choir(sound, 0.22, 1.98, -23, 0.22, attack=0.84, release=0.67)
    air(sound, 0.04, 1.85, 150, 650, 0.67, attack=0.79, release=0.76, seed=6)
    tone(sound, 0.89, 0.44, 102, 40, 0.51, release=0.36, drive=1.7)
    yield "boss_spawn", space(sound, ((0.058, 0.18), (0.133, 0.12), (0.24, 0.07))), -18, -5

    sound = buffer(0.55)
    air(sound, 0, 0.16, 1800, 290, 0.73, attack=0.004, release=0.125, seed=7)
    tone(sound, 0, 0.39, 137, 42, 0.61, attack=0.006, release=0.27, drive=2.5)
    tone(sound, 0.065, 0.32, 67, 35, 0.38, attack=0.011, release=0.24)
    air(sound, 0.071, 0.36, 490, 105, 0.49, attack=0.028, release=0.25, seed=77)
    yield "boss_attack", space(sound, ((0.057, 0.13), (0.102, 0.08))), -19, -6

    sound = buffer(2.55)
    air(sound, 0, 0.18, 3200, 740, 0.83, attack=0.003, release=0.158, seed=8)
    tone(sound, 0, 0.76, 134, 34, 0.78, release=0.64, drive=2.6)
    tone(sound, 0.16, 1.7, 193, 31, 0.30, attack=0.05, release=1.28, drive=2.3)
    air(sound, 0.08, 1.9, 2200, 160, 0.58, attack=0.09, release=1.62, seed=88)
    choir(sound, 0.33, 1.79, -17, 0.25, attack=0.27, release=1.26)
    yield "boss_death", space(sound, ((0.062, 0.24), (0.141, 0.16), (0.287, 0.11))), -18, -5

    sound = buffer(3.25)
    for i, degree in enumerate((0, 7, 12, 16, 19)):
        bell(sound, i * 0.135, 2.25 - i * 0.085, degree, 0.35, metal=0.38)
    for i, degree in enumerate((-12, -5, 0, 4, 12)):
        choir(sound, 0.12 + i * 0.11, 2.65 - i * 0.075, degree, 0.19, attack=0.34, release=1.35)
    yield "victory", space(sound, ((0.061, 0.23), (0.139, 0.16), (0.31, 0.095))), -18, -5

    sound = buffer(2.75)
    for i, degree in enumerate((7, 3, 1, -12)):
        bell(sound, i * 0.26, 1.34, degree, 0.36, metal=0.20)
    for i, degree in enumerate((-12, -11, -24)):
        choir(sound, 0.18 + i * 0.17, 1.91, degree, 0.20, attack=0.30, release=1.09)
    tone(sound, 0.58, 1.73, 63, 35, 0.28, attack=0.21, release=1.20)
    yield "defeat", space(sound, ((0.071, 0.22), (0.158, 0.15), (0.32, 0.08))), -20, -6


def music():
    """An eight-phrase D Phrygian bed. Voices overlap and ring into the next pass."""
    phrase_seconds = 9
    pad_length = 13
    out = buffer(MUSIC_SECONDS + pad_length - phrase_seconds)
    chords = [
        (-12, -5, 0, 3), (-12, -5, 3, 8), (-11, -4, 5, 8), (-12, -7, 0, 7),
        (-12, -5, 3, 10), (-12, -4, 1, 8), (-9, -7, 0, 5), (-12, -5, 1, 7),
    ]
    bells = [
        (2.8, 12), (6.1, 7), (15.1, 15), (20.4, 13), (23.7, 8), (32.5, 12),
        (37.8, 10), (40.9, 15), (48.6, 13), (57.0, 5), (62.5, 7), (70.4, 0),
    ]
    for phrase, chord in enumerate(chords):
        for degree, gain in zip(chord, (0.15, 0.13, 0.095, 0.075)):
            choir(out, phrase * phrase_seconds, pad_length, degree, gain, attack=4.0, release=4.0)
    for start, degree in bells:
        bell(out, start, 4.0, degree, 0.22 if degree < 12 else 0.16, metal=0.36)

    frames = MUSIC_SECONDS * RATE
    for i in range(len(out) - frames):
        out[i] += out[frames + i]
    del out[frames:]

    # Integer cycles keep the drone and its slow amplitude modulation periodic.
    pulse = math.tau / frames
    root = round(pitch(-36) * MUSIC_SECONDS) * pulse
    fifth = round(pitch(-17) * MUSIC_SECONDS) * pulse
    for i in range(frames):
        breath = 0.83 + 0.17 * math.cos(pulse * i * 5)
        drone = 0.18 * math.sin(root * i) + 0.065 * math.sin(2 * root * i + 0.4)
        drone += 0.043 * math.sin(fifth * i + 0.8)
        out[i] += breath * drone
    left = space(out, ((0.061, 0.17), (0.117, 0.13), (0.251, 0.09), (0.417, 0.06)), wrap=True)
    right = space(out, ((0.079, 0.17), (0.159, 0.13), (0.293, 0.09), (0.503, 0.06)), wrap=True)
    return left, right


def write_wav(path, channels, rms_db, peak_db):
    """Match RMS across cues of similar purpose and gently limit the highest peaks."""
    frames = len(channels[0])
    rms = math.sqrt(sum(math.fsum(s * s for s in ch) for ch in channels) / (frames * len(channels)))
    gain = 10 ** (rms_db / 20) / rms
    ceiling = 10 ** (peak_db / 20)
    knee = 0.72 * ceiling
    width = ceiling - knee
    pcm = array("h")
    for frame in zip(*channels):
        for sample in frame:
            value = sample * gain
            if abs(value) > knee:
                limited = knee + width * math.tanh((abs(value) - knee) / width)
                value = math.copysign(limited, value)
            pcm.append(round(value * 32767))
    with wave.open(str(path), "wb") as destination:
        destination.setparams((len(channels), 2, RATE, frames, "NONE", "not compressed"))
        if sys.byteorder == "big":
            pcm.byteswap()
        destination.writeframes(pcm.tobytes())


def main():
    folder = Path(sys.argv[1] if len(sys.argv) > 1 else "eight/assets/audio/placeholder")
    folder.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory() as work:
        work = Path(work)
        for name, sound, rms_db, peak_db in sfx():
            assert sound[0] == sound[-1] == 0.0, name
            write_wav(work / f"placeholder_{name}.wav", (sound,), rms_db, peak_db)

        left, right = music()
        for channel in (left, right):
            seam = abs(channel[0] - channel[-1])
            assert seam <= max(abs(channel[i] - channel[i - 1]) for i in range(1, RATE // 4))
        temp = work / "music.wav"
        write_wav(temp, (left, right), -22, -8)
        # A 10 ms taper keeps Vorbis boundary error below the pad's own sample changes.
        taper = f"afade=in:d=0.01:curve=hsin,afade=out:st={MUSIC_SECONDS - 0.01}:d=0.01:curve=hsin"
        subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y", "-i", str(temp), "-af", taper, "-c:a", "libvorbis",
             "-q:a", "5", str(work / "placeholder_music_loop.ogg")],
            check=True,
        )
        for asset in work.glob("placeholder_*"):
            (folder / asset.name).write_bytes(asset.read_bytes())


if __name__ == "__main__":
    main()
