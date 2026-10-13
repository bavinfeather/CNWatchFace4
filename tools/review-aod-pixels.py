"""24-hour AOD geometry check with the original bitmap fonts; native heat-map remains separate."""
from pathlib import Path
import json
import math
import re
from PIL import Image, ImageChops, ImageDraw

root = Path(__file__).resolve().parents[1]
def font(folder, name):
    glyphs = {}
    for line in (folder / (name + '.fnt')).read_text().splitlines():
        if line.startswith('char id='):
            g = {k: int(v) for k, v in re.findall(r'(\w+)=(-?\d+)', line)}
            glyphs[chr(g['id'])] = g
    alpha = Image.open(folder / (name + '.png')).getchannel('A')
    return glyphs, alpha
def text_mask(target, font_data, text, center, y):
    glyphs, alpha = font_data
    x = center - sum(glyphs[c]['xadvance'] for c in text) // 2
    for c in text:
        g = glyphs[c]
        glyph = alpha.crop((g['x'], g['y'], g['x'] + g['width'], g['y'] + g['height']))
        layer = Image.new('L', target.size)
        layer.paste(glyph, (x + g['xoffset'], y + g['yoffset']))
        target = ImageChops.lighter(target, layer)
        x += g['xadvance']
    return target
results = []
for size in (360, 390, 416, 454, 466):
    folder = root / f'resources-{size}/fonts'
    fonts = [font(folder, 'Aod'), font(folder, 'Small')]
    scale = size / 280
    for twelve_hour in (False, True):
        previous = None
        peak_on = 0
        overlap = 0
        clipped = 0
        screen = Image.new('L', (size, size))
        ImageDraw.Draw(screen).ellipse((0, 0, size - 1, size - 1), fill=255)
        for minute in range(1441):  # include midnight wrap
            clock = minute % 1440
            hour = clock // 60
            if twelve_hour:
                hour = hour % 12 or 12
            center = int((140 + clock % 5 - 2) * scale)
            shift = -70 if clock % 2 == 0 else 70
            mask = Image.new('L', (size, size))
            for f, text, base_y in ((fonts[0], f'{hour:02}:{clock % 60:02}', 105),
                                    (fonts[1], '12/31', 151), (fonts[1], '100%', 177)):
                mask = text_mask(mask, f, text, center, int((base_y + shift) * scale))
            mask = mask.point(lambda a: 255 if a > 0 else 0)
            peak_on = max(peak_on, mask.histogram()[255])
            clipped = max(clipped, ImageChops.subtract(mask, screen).histogram()[255])
            if previous is not None:
                overlap = max(overlap, ImageChops.multiply(mask, previous).histogram()[255])
            previous = mask
        percentage = peak_on / screen.histogram()[255] * 100
        results.append({'resolution': size, 'format': '12h' if twelve_hour else '24h',
                        'frames': 1441, 'maxAdjacentOverlap': overlap,
                        'peakLitPercent': percentage, 'clippedPixels': clipped,
                        'bitmapFallbackSmallFont': True, 'nativeHeatMap': False})
        if overlap != 0 or percentage > 10 or clipped != 0:
            raise RuntimeError(f'AOD geometry failed: {results[-1]}')
(root / 'evidence/aod-pixel-check.json').write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps(results, indent=2))
