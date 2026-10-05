"""Synthesizes the game's sound effects as small 16-bit mono WAV files.

Run: python3 tools/make_sfx.py  (writes into MyApp/Audio/Sounds)
"""
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'MyApp', 'Audio', 'Sounds')
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.004, decay=6.0):
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1) if attack > 0 else 1
    return a * np.exp(-decay * x)


def tone(freq, sec, decay=6.0, attack=0.004, harmonics=((1, 1.0),), vibrato=0.0):
    x = t(sec)
    f = freq * (1 + vibrato * np.sin(2 * np.pi * 6 * x))
    phase = 2 * np.pi * np.cumsum(f) / SR
    s = sum(a * np.sin(h * phase) for h, a in harmonics)
    return s * env(len(x), attack, decay)


def sweep(f0, f1, sec, decay=4.0, shape='sine'):
    x = t(sec)
    f = f0 * (f1 / f0) ** (x / sec)
    phase = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(phase) if shape == 'sine' else np.sign(np.sin(phase)) * 0.6
    return s * env(len(x), 0.003, decay)


def noise(sec, decay=10.0, lp=0.15):
    n = rng.standard_normal(int(SR * sec))
    y = np.zeros_like(n)
    acc = 0.0
    for i, v in enumerate(n):
        acc += lp * (v - acc)
        y[i] = acc
    return y / (np.abs(y).max() + 1e-9) * env(len(n), 0.002, decay)


def mix(*parts):
    n = max(len(p) for _, p in parts)
    out = np.zeros(n + int(SR * 0.01))
    for start, p in parts:
        i = int(SR * start)
        out[i:i + len(p)] += p[: max(0, len(out) - i)]
    return out


def bell(freq, sec=0.5, decay=5.0):
    return tone(freq, sec, decay, harmonics=((1, 1.0), (2.01, 0.35), (3.02, 0.18), (4.2, 0.08)))


def save(name, y, gain_db=-3.0):
    y = np.tanh(y * 1.2)
    y = y / (np.abs(y).max() + 1e-9) * (10 ** (gain_db / 20))
    fade = int(SR * 0.006)
    y[-fade:] *= np.linspace(1, 0, fade)
    data = (y * 32767).astype('<i2').tobytes()
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def sparkle(sec=0.35, count=6, base=2600):
    parts = []
    for k in range(count):
        f = base * (1 + 0.5 * rng.random())
        parts.append((k * sec / count, tone(f, 0.12, 30, harmonics=((1, 1.0), (2, 0.2))) * 0.5))
    return mix(*parts)


os.makedirs(OUT, exist_ok=True)

save('tap', mix((0, tone(1250, 0.05, 70, attack=0.001, harmonics=((1, 1.0), (2.4, 0.2)))), (0, noise(0.03, 120, 0.5) * 0.15)), -9)
save('coin', mix((0, bell(1318.5, 0.12, 25)), (0.07, bell(1760.0, 0.35, 9))), -5)
save('cash', mix((0, noise(0.08, 40, 0.35) * 0.6), (0.03, bell(2093, 0.6, 6)), (0.03, bell(2637, 0.5, 7) * 0.5)), -4)
save('pop', sweep(700, 180, 0.09, 30), -6)
save('upgrade', mix((0, sweep(380, 1300, 0.18, 5)), (0.12, sparkle(0.25, 4, 2400) * 0.6)), -4)
arp = [523.25, 659.25, 783.99, 1046.5]
save('levelup', mix(*[(i * 0.085, tone(f, 0.35, 7, harmonics=((1, 1.0), (2, 0.3), (3, 0.15)))) for i, f in enumerate(arp)],
                    (0.34, tone(523.25, 0.7, 3, harmonics=((1, 0.6), (2, 0.2)))),
                    (0.34, tone(659.25, 0.7, 3) * 0.5), (0.34, tone(783.99, 0.7, 3) * 0.5),
                    (0.36, sparkle(0.45, 7, 3000) * 0.5)), -3)
save('error', mix((0, sweep(220, 200, 0.12, 8, 'square')), (0.13, sweep(170, 150, 0.16, 8, 'square'))), -8)
save('chest', mix((0, noise(0.45, 4, 0.06) * np.linspace(0.2, 1, int(SR * 0.45))), (0.38, bell(1567.98, 0.6, 6)), (0.4, sparkle(0.5, 8, 2800) * 0.6)), -3)
save('reward', mix((0, tone(783.99, 0.9, 3, harmonics=((1, 1.0), (2, 0.25)))), (0.05, tone(987.77, 0.85, 3) * 0.7),
                   (0.1, tone(1174.66, 0.8, 3) * 0.6), (0.12, sparkle(0.6, 9, 3200) * 0.6)), -4)
save('whoosh', noise(0.28, 6, 0.05) * np.sin(np.linspace(0, np.pi, int(SR * 0.28))), -8)
save('tick', tone(2200, 0.025, 160, attack=0.0005), -12)
save('wrong', sweep(330, 160, 0.22, 6, 'square'), -9)
save('correct', mix((0, bell(1046.5, 0.15, 18)), (0.06, bell(1568.0, 0.25, 12))), -7)
print(sorted(os.listdir(OUT)))
