"""The dial-in's modem handshake (punch list 104; the director, Nov 7 2026: "a short 1993 modem handshake sound").

Made here from nothing but sine waves and noise, so it is ours: a dial tone, seven DTMF digits (the standard row and
column pairs), the answer tone (2100 Hz with its phase reversals), then the handshake's chirps and the scrambled noise of
two modems training, the way a 14.4k call sounded. About 4 seconds, mono 22050 Hz 16-bit, quiet enough under the UI.

Writes 42/media/sound/ZeD_modem.wav, a plain PCM WAV like the game's own clips (its sound scripts name .wav files);
media/scripts/ZeD_Sounds.txt names it as the UI sound ZeDModemDial, so it plays on the game's UI volume.

Usage (from the repo root):  <ComfyUI venv python> -I ZeDUI/tools/sound/make_modem.py
Deterministic: the noise has a fixed seed, so a run gives the same file.
"""
import os
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "sound", "ZeD_modem.wav")
SR = 22050
rng = np.random.default_rng(1993)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def tone(freqs, sec, amp=0.3):
    x = t(sec)
    return amp * sum(np.sin(2 * np.pi * f * x) for f in freqs) / len(freqs)


def env(sig, a=0.005, r=0.01):
    n = len(sig)
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    if na: e[:na] = np.linspace(0, 1, na)
    if nr: e[-nr:] = np.linspace(1, 0, nr)
    return sig * e


def silence(sec):
    return np.zeros(int(SR * sec))


DTMF = {"1": (697, 1209), "2": (697, 1336), "3": (697, 1477), "4": (770, 1209), "5": (770, 1336), "6": (770, 1477),
        "7": (852, 1209), "8": (852, 1336), "9": (852, 1477), "0": (941, 1336)}

parts = []
parts.append(env(tone((350, 440), 0.45, 0.22)))                          # the dial tone
parts.append(silence(0.08))
for d in "5550193":                                                        # seven digits, tone dialing
    parts.append(env(tone(DTMF[d], 0.075, 0.28)))
    parts.append(silence(0.05))
parts.append(silence(0.25))
# the answer tone: 2100 Hz, its phase turned over every 0.45 s
x = t(0.7)
ans = np.sin(2 * np.pi * 2100 * x + np.pi * (np.floor(x / 0.45) % 2))
parts.append(env(0.2 * ans, 0.01, 0.02))
# the handshake: a falling-rising chirp, two alternating tones, then the training noise
x = t(0.35)
f = 1800 - 900 * np.sin(np.pi * x / 0.35)
parts.append(env(0.2 * np.sin(2 * np.pi * np.cumsum(f) / SR)))
x = t(0.4)
alt = np.where((np.floor(x * 24) % 2) == 0, np.sin(2 * np.pi * 980 * x), np.sin(2 * np.pi * 1180 * x))
parts.append(env(0.18 * alt))
x = t(0.9)
noise = rng.normal(0, 1, len(x))
# band-limited: a short moving average takes the hiss off, a slow wobble gives it the training's swell
kernel = np.ones(6) / 6
noise = np.convolve(noise, kernel, mode="same")
swell = 0.6 + 0.4 * np.sin(2 * np.pi * 3.5 * x)
carrier = np.sin(2 * np.pi * 1650 * x) * 0.35
parts.append(env(0.16 * (noise * swell + carrier), 0.02, 0.15))

sig = np.concatenate(parts)
sig = sig / max(1e-9, np.max(np.abs(sig))) * 0.6
pcm = (sig * 32767).astype("<i2")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("wrote", OUT, round(len(sig) / SR, 2), "s")
