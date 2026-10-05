"""Copies Fluent 3D emoji PNGs (MIT, Microsoft) into the asset catalog as image sets.

Usage: python3 tools/install_art.py <png_dir> <key> [<key> ...]
       python3 tools/install_art.py <png_dir> --from-swift MyApp
The second form scans Swift sources for Art keys like "food_falafel" and installs exactly those.
Images land in MyApp/Assets.xcassets/Art/<key>.imageset, tagged @3x (256px -> 85pt).
"""
import json
import os
import re
import shutil
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..')
CATALOG = os.path.join(ROOT, 'MyApp', 'Assets.xcassets', 'Art')
PREFIXES = ('food_', 'ppl_', 'face_', 'bld_', 'veh_', 'ui_', 'ani_')


def keys_from_swift(src):
    pat = re.compile(r'"((?:%s)[a-z0-9_]+)"' % '|'.join(PREFIXES))
    found = set()
    for d, _, files in os.walk(os.path.join(ROOT, src)):
        for f in files:
            if f.endswith('.swift'):
                found.update(pat.findall(open(os.path.join(d, f), encoding='utf-8').read()))
    return sorted(found)


def main():
    png_dir = sys.argv[1]
    keys = keys_from_swift(sys.argv[3]) if sys.argv[2] == '--from-swift' else sys.argv[2:]
    os.makedirs(CATALOG, exist_ok=True)
    with open(os.path.join(CATALOG, 'Contents.json'), 'w') as f:
        json.dump({'info': {'author': 'xcode', 'version': 1}, 'properties': {'provides-namespace': False}}, f, indent=2)
    wanted = set(keys)
    for name in os.listdir(CATALOG):
        if name.endswith('.imageset') and name[:-9] not in wanted:
            shutil.rmtree(os.path.join(CATALOG, name))
    missing = []
    for k in keys:
        src = os.path.join(png_dir, k + '.png')
        if not os.path.exists(src):
            missing.append(k)
            continue
        d = os.path.join(CATALOG, k + '.imageset')
        os.makedirs(d, exist_ok=True)
        shutil.copyfile(src, os.path.join(d, k + '.png'))
        with open(os.path.join(d, 'Contents.json'), 'w') as f:
            json.dump({'images': [{'filename': k + '.png', 'idiom': 'universal', 'scale': '3x'}],
                       'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
    print(f'installed {len(keys) - len(missing)} images; missing: {missing}')
    if missing:
        sys.exit(1)


if __name__ == '__main__':
    main()
