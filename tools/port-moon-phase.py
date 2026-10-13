"""Generate the scoped Monkey C port from the pinned BSD-2-Clause SunCalc source."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
src = (root / 'assets/suncalc/index.js').read_text(encoding='utf-8')
def function(name):
    start = src.index('function ' + name + '(')
    brace = src.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (src[end] == '{') - (src[end] == '}')
        end += 1
    return src[start:end]
parts = []
for name in ('moonLon', 'moonLat'):
    data = re.search(r'const ' + name + r' = new Int32Array\(\[([\s\S]*?)\]\);', src).group(1)
    parts.append('const ' + name + ' = [' + data + '];')
for name in ('deltaT', 'sunCoords', 'nutationObliquity', 'moonCoords'):
    body = function(name)
    body = re.sub(r'\b(const|let)\b', 'var', body)
    body = body.replace('===', '==').replace('.length', '.size()')
    body = body.replace('return {dpsi, eps: rad * (eps0 + deps)};', 'return [dpsi, rad * (eps0 + deps)];')
    body = body.replace('var {dpsi, eps} = nutationObliquity(t);', 'var nut = nutationObliquity(t); var dpsi = nut[0]; var eps = nut[1];')
    body = body.replace('var Dr = rad * D, Mr = rad * M, Mpr = rad * Mp, Fr = rad * F;',
                        'var Dr=rad*D; var Mr=rad*M; var Mpr=rad*Mp; var Fr=rad*F;')
    body = body.replace('var sl = 0, sr = 0, sb = 0;', 'var sl=0.0d; var sr=0.0d; var sb=0.0d;')
    body = body.replace('var A1r = rad * A1, Lpr = rad * Lp;', 'var A1r=rad*A1; var Lpr=rad*Lp;')
    body = re.sub(r'return \{\s*ra: (.*?), // 25.6\s*dec: (.*?)\s*// 25.7\s*\};', r'return [\1, \2];', body)
    body = re.sub(r'return \{\s*ra: (.*?),\s*// 13.3\s*dec: (.*?),\s*// 13.4\s*dist: (.*?)\s*// distance to the Moon in km\s*\};', r'return [\1, \2, \3];', body)
    body = re.sub(r'\b(sin|cos|tan|asin|acos|sqrt|floor)\(', r'Math.\1(', body)
    body = re.sub(r'\batan\(', 'Math.atan2(', body)
    body = re.sub(r'(?<![\w.])(\d+\.\d+)(?![\w.])', r'\1d', body)
    body = re.sub(r'\b1 / (\d+)', r'1.0d / \1', body)
    parts.append(body)
phase = '''function phase(seconds) {
    // Subtract the J2000 Unix epoch before division, avoiding a large Float JD.
    var d=(seconds-946728000).toDouble()/86400.0d;
    d+=deltaT(d)/86400.0d;
    var s=sunCoords(d); var m=moonCoords(d);
    var dot=Math.sin(s[1])*Math.sin(m[1])+Math.cos(s[1])*Math.cos(m[1])*Math.cos(s[0]-m[0]);
    if(dot>1) { dot=1.0d; } if(dot< -1) { dot= -1.0d; }
    var phi=Math.acos(dot);
    var inc=Math.atan2(149598000.0d*Math.sin(phi),m[2]-149598000.0d*Math.cos(phi));
    var angle=Math.atan2(Math.cos(s[1])*Math.sin(s[0]-m[0]),
        Math.sin(s[1])*Math.cos(m[1])-Math.cos(s[1])*Math.sin(m[1])*Math.cos(s[0]-m[0]));
    return 0.5d+0.5d*inc*(angle<0?-1:1)/PI;
}'''
header = '// Adapted from pinned mourner/suncalc; Copyright (c) 2026 Volodymyr Agafonkin.\n// BSD-2-Clause: assets/suncalc/LICENSE. Coordinate/illumination subset only.\nimport Toybox.Math;\nclass MoonPhase {\n    const PI=3.141592653589793d;\n    const rad=0.017453292519943295d;\n'
(root / 'source/MoonPhase.mc').write_text(header + '\n'.join(parts) + '\n' + phase + '\n}\n', encoding='utf-8')
print('Generated scoped SunCalc coordinate and illumination port.')
