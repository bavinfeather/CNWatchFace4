"""Assemble the approved crop and unretouched simulator capture for comparison."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
out = root / "evidence" / "screenshots"
reference = Image.open(root / "assets/reference/approved-sheet-07.png").convert("RGB")
# Only the AMOLED watch surface from card 07. Keep the original proportions.
crop = reference.crop((20, 1173, 264, 1455))
crop.save(out / "approved-07-amoled-crop.png")
runtime = Image.open(out / "f9-pro51-07-fixture-1808.png").convert("RGB")
canvas = Image.new("RGB", (1160, 800), "#F4F5F7")
draw = ImageDraw.Draw(canvas)
font_path = "C:/Windows/Fonts/msyh.ttc"
title = ImageFont.truetype(font_path, 30)
label = ImageFont.truetype(font_path, 22)
small = ImageFont.truetype(font_path, 17)
draw.text((42, 25), "07 与实际运行画面对照", font=title, fill="#17202A")
draw.text((65, 88), "07 选定设计 · A屏", font=label, fill="#17202A")
draw.text((615, 88), "F9 Pro 51 实际运行 · 样本数据", font=label, fill="#17202A")
for x in (35, 590):
    draw.rounded_rectangle((x, 128, x+535, 661), radius=16, fill="white")
crop = crop.resize((round(crop.width*480/crop.height),480),Image.Resampling.LANCZOS)
# Isolate the selected elliptical surface from the adjacent MIP mockup.
ref_mask=Image.new("L",crop.size,0)
ImageDraw.Draw(ref_mask).ellipse((0,0,crop.width-1,crop.height-1),fill=255)
canvas.paste(crop, (35+(535-crop.width)//2, 150),ref_mask)
# The simulator exports a square framebuffer; exclude only the corners that
# the physical round display cannot show. No pixels within the face are edited.
runtime = runtime.resize((480, 480), Image.Resampling.LANCZOS)
mask = Image.new("L", (480, 480), 0)
ImageDraw.Draw(mask).ellipse((0, 0, 479, 479), fill=255)
canvas.paste(runtime, (617, 150), mask)
draw.text((65, 635), "原图截取，保持比例；未重画", font=small, fill="#68717B")
draw.text((615, 635), "原始 466px 截图，仅按实际圆屏裁去四角", font=small, fill="#68717B")
draw.text((42, 692), "共同样本：18:08 / THU 01 / 18° / 8.2k / BB 88 / ALT 1286m", font=small, fill="#17202A")
draw.text((42, 727), "结论：外观对照未通过。字体比例、山体细节、峡谷与光照仍有明显差距。", font=small, fill="#9C3E22")
draw.text((42, 759), "正式绘制代码未修改；右图为独立预览程序调用同一绘制代码所得。", font=small, fill="#68717B")
canvas.save(out / "07-vs-f9-runtime.png")
print(out / "07-vs-f9-runtime.png")
