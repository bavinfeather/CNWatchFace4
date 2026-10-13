"""One licensed geometric family for active data, English labels and units."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
font_folder = root / 'assets/fonts/barlow'
numeric = '0123456789.-kftmh%'
labels = ''.join(dict.fromkeys(numeric+'STEPSBBALTBATSTRESSRECOVERYCLEARPARTLYCLOUDYRAINSNOWSTORMFOGRAIN/SNOWHAILDUSTICEWIND/'))
for resolution in (360, 390, 416, 454, 466):
    for name, base, chars in [('Field07', 26, numeric), ('Compact07', 18, numeric),
                              ('LabelEn07', 13, labels), ('Unit07', 11, 'kmfth%')]:
        target = round(base * resolution / 280)
        weight = 'Bold' if name in ('Field07', 'Compact07') else 'SemiBold'
        font = ImageFont.truetype(str(font_folder / f'BarlowCondensed-{weight}.ttf'), 120)
        boxes = [font.getbbox(c) for c in chars]
        top = min(b[1] for b in boxes)
        extent = max(b[3] for b in boxes) - top
        ratio = target / extent
        advances = [round(font.getlength(c) * ratio) for c in chars]
        cell = max(advances) + 4
        columns = min(16, 512 // cell)
        rows = (len(chars) + columns - 1) // columns
        atlas = Image.new('RGBA', (columns * cell, rows * (target + 2)), (255, 255, 255, 0))
        lines = [f'info face="Barlow Condensed {weight}" size={target} bold=1 italic=0 unicode=1 smooth=1 aa=4',
                 f'common lineHeight={target} base={target} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0',
                 f'page id=0 file="{name}.png"', f'chars count={len(chars)}']
        for index, c in enumerate(chars):
            width = round(font.getlength(c)) + 4
            mask = Image.new('L', (width, extent))
            ImageDraw.Draw(mask).text((0, -top), c, font=font, fill=255)
            glyph_width = max(1, round(width * ratio))
            mask = mask.resize((glyph_width, target), Image.Resampling.LANCZOS)
            # The CIQ bitmap-font compiler counts nonzero alpha as coverage.
            # Remove resampling ringing rather than creating stray contours.
            mask = mask.point(lambda value: 255 if value >= 128 else 0)
            glyph = Image.new('RGBA', mask.size, (255, 255, 255, 0))
            glyph.putalpha(mask)
            x = index % columns * cell
            y = index // columns * (target + 2)
            atlas.paste(glyph, (x, y))
            lines.append(f'char id={ord(c)} x={x} y={y} width={glyph_width} height={target} xoffset=0 yoffset=0 xadvance={advances[index]} page=0 chnl=15')
        folder = root / f'resources-{resolution}/fonts'
        atlas.save(folder / f'{name}.png')
        (folder / f'{name}.fnt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
        xml = folder / 'fonts.xml'
        text = xml.read_text(encoding='utf-8')
        if f'id="{name}"' not in text:
            xml.write_text(text.replace('</fonts>', f'<font id="{name}" filename="{name}.fnt" antialias="true"/></fonts>'), encoding='utf-8')
    print(resolution, 'active field fonts generated')
