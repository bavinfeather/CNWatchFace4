"""Build only the AMOLED active digits; AOD resources are never rewritten."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
source = root / 'assets/fonts/barlow/BarlowSemiCondensed-Bold.ttf'
for resolution in (360, 390, 416, 454, 466):
    scale = resolution / 280
    height = round(55 * scale)
    advance = round(44 * scale)
    atlas = Image.new('RGBA', ((advance + 2) * 10, height + 2))
    font = ImageFont.truetype(str(source), 240)
    lines = [
        'info face="Barlow Semi Condensed Bold" size=%d bold=1 italic=0 unicode=1 smooth=1 aa=4' % height,
        'common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0' % (height, height, atlas.width, atlas.height),
        'page id=0 file="Time07.png"', 'chars count=10',
    ]
    for index, character in enumerate('0123456789'):
        bounds = font.getbbox(character)
        mask = Image.new('L', (bounds[2] - bounds[0], bounds[3] - bounds[1]))
        ImageDraw.Draw(mask).text((-bounds[0], -bounds[1]), character, font=font, fill=255)
        mask = mask.crop(mask.getbbox())
        # Keep the natural glyph proportions inside a common aligned digit cell.
        target_width = round(mask.width * height / mask.height)
        mask = mask.resize((target_width, height), Image.Resampling.LANCZOS)
        # The bitmap-font compiler treats every nonzero alpha as coverage.
        # Remove Lanczos ringing before export, rather than adding a second contour.
        mask = mask.point(lambda value: 255 if value >= 128 else 0)
        glyph = Image.new('RGBA', mask.size, (255, 255, 255, 0))
        glyph.putalpha(mask)
        x = index * (advance + 2)
        atlas.paste(glyph, (x, 0))
        lines.append('char id=%d x=%d y=0 width=%d height=%d xoffset=%d yoffset=0 xadvance=%d page=0 chnl=15' %
                     (ord(character), x, target_width, height, (advance - target_width) // 2, advance))
    destination = root / ('resources-%d/fonts' % resolution)
    atlas.save(destination / 'Time07.png')
    (destination / 'Time07.fnt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    xml = destination / 'fonts.xml'
    text = xml.read_text(encoding='utf-8')
    if 'id="Time07"' not in text:
        xml.write_text(text.replace('</fonts>', '<font id="Time07" filename="Time07.fnt"/></fonts>'), encoding='utf-8')
    print(resolution, 'digits height', height, 'two-digit width', advance * 2)
