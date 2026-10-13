"""Convert upstream Weather Icons glyphs to small Connect IQ images; no new artwork."""
from pathlib import Path
import csv
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
source = root / 'assets/moon/weathericons-regular-webfont.ttf'
rows = list(csv.reader((root / 'assets/moon/moon.csv').read_text().splitlines()))[:28]
font = ImageFont.truetype(str(source), 160)
bounds = font.getbbox(chr(0xf0a3))
frame = 32
output = root / 'resources/drawables/moon'
output.mkdir(exist_ok=True)
images = []
xml = ['<drawables>', '    <bitmap id="LauncherIcon" filename="icon.png"/>']
for index, (name, code) in enumerate(rows):
    mask = Image.new('L', (bounds[2] - bounds[0], bounds[3] - bounds[1]))
    ImageDraw.Draw(mask).text((-bounds[0], -bounds[1]), chr(int(code.strip(), 16)), font=font, fill=255)
    mask = mask.resize((30, 30), Image.Resampling.LANCZOS).point(lambda v: 255 if v >= 128 else 0)
    glyph = Image.new('RGBA', mask.size, (255, 255, 255, 0))
    glyph.putalpha(mask)
    image = Image.new('RGBA', (frame, frame))
    image.paste(glyph, (1, 1))
    out = output / f'phase-{index:02}.png'
    image.save(out)
    images.append({'file': out.relative_to(root).as_posix(), 'sha256': hashlib.sha256(out.read_bytes()).hexdigest()})
    xml.append(f'    <bitmap id="LandscapeMoon{index}" filename="moon/phase-{index:02}.png" dithering="none" automaticPalette="false"/>')
xml.append('</drawables>')
(root / 'resources/drawables/drawables.xml').write_text('\n'.join(xml) + '\n')
record = {'repository': 'https://github.com/erikflowers/weather-icons',
          'commit': 'bb80982bf1f43f2d57f9dd753e7413bf88beb9ed', 'license': 'OFL-1.1',
          'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'images': images,
          'frameSize': frame, 'phases': [r[0].strip() for r in rows]}
(root / 'evidence/moon-asset-source.json').write_text(json.dumps(record, indent=2) + '\n')
print('Converted 28 upstream moon glyphs:', output)
