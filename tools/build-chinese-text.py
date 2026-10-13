"""A small licensed CJK fallback subset, without touching the time/AOD fonts."""
from pathlib import Path
from shutil import copyfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT/'assets/fonts'
ASSETS.mkdir(exist_ok=True)
for name in ('NotoSansSC.ttf', 'NotoSansSC-OFL.txt'):
    if not (ASSETS/name).exists():
        copyfile(ROOT.parent/'CNWatchFace3/assets/fonts'/name, ASSETS/name)
CHARS = ''.join(dict.fromkeys('0123456789 .-/%kmfth周日一二三四五六步数身体电量海拔压力恢复时间晴少云多雨雪雷雾未知冰雹沙尘风暴结大'))
for size in (360,390,416,454,466):
    folder=ROOT/f'resources-{size}/fonts'
    for name, base in (('LabelZh',14),('DateZh',22)):
        px=round(base*size/280)
        font=ImageFont.truetype(str(ASSETS/'NotoSansSC.ttf'),px)
        font.set_variation_by_axes([500])
        boxes=[font.getbbox(c) for c in CHARS]
        top=min(b[1] for b in boxes); height=max(b[3] for b in boxes)-top
        cell=max(round(font.getlength(c)) for c in CHARS)+3
        cols=min(16,512//cell); rows=(len(CHARS)+cols-1)//cols
        atlas=Image.new('RGBA',(cols*cell,rows*(height+2)),(255,255,255,0))
        draw=ImageDraw.Draw(atlas)
        lines=[f'info face="Noto Sans SC" size={px} bold=0 italic=0 unicode=1 smooth=1 aa=2',
               f'common lineHeight={height} base={height} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0',
               f'page id=0 file="{name}.png"',f'chars count={len(CHARS)}']
        for index,c in enumerate(CHARS):
            x=index%cols*cell; y=index//cols*(height+2)
            draw.text((x,y-top),c,font=font,fill='white')
            lines.append(f'char id={ord(c)} x={x} y={y} width={cell-1} height={height} xoffset=0 yoffset=0 xadvance={round(font.getlength(c))} page=0 chnl=15')
        atlas.save(folder/f'{name}.png')
        (folder/f'{name}.fnt').write_text('\n'.join(lines)+'\n',encoding='utf-8')
        xml=folder/'fonts.xml'
        text=xml.read_text(encoding='utf-8')
        if f'id="{name}"' not in text:
            xml.write_text(text.replace('</fonts>',f'<font id="{name}" filename="{name}.fnt" antialias="true"/></fonts>'),encoding='utf-8')
    print(size, 'CJK date/weather/field fallback generated')
