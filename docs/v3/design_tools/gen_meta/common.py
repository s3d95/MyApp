"""Shared helpers for the meta-content generators (non-city content files).

Every generator builds plain Python dicts and writes them with write_json().
Output folder: design/content/. Field order follows SCHEMA.md ("version" first).
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
DESIGN = os.path.abspath(os.path.join(HERE, "..", ".."))
CONTENT = os.path.join(DESIGN, "content")
ART_KEYS_PATH = "/home/user/MyApp/tools/art_keys.txt"


def G(m, f=None):
    """Gendered text. G('x') -> plain string; G('x','y') -> {m,f}."""
    if f is None or f == m:
        return m
    return {"m": m, "f": f}


def R(type_, amount=1, id=None, rarity=None):
    """Reward object (SCHEMA 0.3)."""
    r = {"type": type_, "amount": amount}
    if id is not None:
        r["id"] = id
    if rarity is not None:
        r["rarity"] = rarity
    return r


# ---- reward shorthands ----
def gold(n): return R("gold", n)
def xp(n): return R("xp", n)
def rep(n): return R("rep", n)
def sp(n): return R("seasonPoints", n)
def tickets(n): return R("tickets", n)
def freezes(n): return R("freezes", n)
def zaatar(n=1): return R("zaatar", n)
def warp(minutes): return R("timeWarpMin", minutes)
def incmin(minutes): return R("incomeMin", minutes)
def chest(kind, n=1): return R("chest", n, id=kind)
def cards(n, id=None, rarity=None): return R("chefCards", n, id=id, rarity=rarity)
def item(n=1, id=None, rarity=None): return R("heritageItem", n, id=id, rarity=rarity)
def hcase(n=1): return R("heritageCase", n)
def tokens(n): return R("eventTokens", n)
def cosmetic(cid): return R("cosmetic", 1, id=cid)
def scene(sid): return R("storyScene", 1, id=sid)


# ---- effect shorthands (SCHEMA 0.5) ----
def scope_all(): return {"kind": "all"}
def scope_cat(v): return {"kind": "category", "value": v}
def scope_cui(v): return {"kind": "cuisine", "value": v}
def scope_wt(v): return {"kind": "weatherTag", "value": v}


def e_income(scope, mult, layer, durationSec=None):
    e = {"type": "incomeMult", "scope": scope, "mult": mult, "layer": layer}
    if durationSec is not None:
        e["durationSec"] = durationSec
    return e


def e_active(mult, minutes, scope=None):
    return e_income(scope or scope_all(), mult, "active", minutes * 60)


def e_reward(r): return {"type": "reward", "reward": r}
def e_karma(d): return {"type": "karma", "delta": d}
def e_flag(f): return {"type": "setFlag", "flag": f}
def e_scene(s): return {"type": "storyScene", "sceneId": s}
def e_stake(m): return {"type": "stake", "minutes": m}
def e_frenzy(mult=5, sec=60): return {"type": "frenzy", "mult": mult, "durationSec": sec}
def e_special(): return {"type": "spawnSpecial"}
def e_freeRush(): return {"type": "freeRushRound"}
def e_collect(cid, n): return {"type": "collectibleBonus", "collectibleId": cid, "amount": n}


def sig3(x):
    """Round to 3 significant digits."""
    if x == 0:
        return 0.0
    d = math.floor(math.log10(abs(x)))
    f = 10 ** (d - 2)
    return float(round(x / f) * f) if d >= 2 else round(x, 2 - d)


def write_json(name, obj):
    os.makedirs(CONTENT, exist_ok=True)
    path = os.path.join(CONTENT, name)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    return path


def load_json(name):
    path = os.path.join(CONTENT, name)
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)
