"""Pin Lucide SVG sources and license; SVG rasterization is done by sharp."""
import json
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / 'assets/lucide-short-fields'
source.mkdir(parents=True, exist_ok=True)
def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'CNWatchFace4-assets'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()
commit = json.loads(fetch('https://api.github.com/repos/lucide-icons/lucide/commits/main'))['sha']
base = f'https://raw.githubusercontent.com/lucide-icons/lucide/{commit}'
names = ['footprints', 'battery-plus', 'mountain', 'battery', 'activity', 'timer']
for name in names:
    (source / f'{name}.svg').write_bytes(fetch(f'{base}/icons/{name}.svg'))
(source / 'LICENSE').write_bytes(fetch(f'{base}/LICENSE'))
(source / 'source.json').write_text(json.dumps({'repository':'https://github.com/lucide-icons/lucide',
    'commit':commit, 'icons':names, 'adaptation':'stroke color #C4D1DB; 32px transparent PNG'}, indent=2))
print(commit)
