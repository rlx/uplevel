# Regenerates assets/social-preview.png, the 1280x640 card GitHub shows when the
# repository URL is shared. Run from the repository root:
#   python3 assets/social-preview.py
#
# Needs Pillow and the San Francisco fonts that ship with macOS. It is here so
# the card can be changed with the copy it quotes, rather than being an image
# nobody can edit.
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 640
BG     = (11, 14, 20)
PANEL  = (18, 23, 32)
WHITE  = (233, 237, 243)
MUTED  = (139, 148, 158)
ACCENT = (126, 231, 135)
RULE   = (34, 41, 53)

SANS = "/System/Library/Fonts/SFNS.ttf"
MONO = "/System/Library/Fonts/SFNSMono.ttf"

def sans(size, style="Regular"):
    f = ImageFont.truetype(SANS, size)
    f.set_variation_by_name(style)
    return f

def mono(size, style="Regular"):
    f = ImageFont.truetype(MONO, size)
    try:
        f.set_variation_by_name(style)
    except Exception:
        pass
    return f

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
M = 88

d.rectangle([0, 0, 10, H], fill=ACCENT)

f_eyebrow = sans(24, "Semibold")
d.text((M, 78), "A CLAUDE CODE SKILL", font=f_eyebrow, fill=ACCENT)

f_title = sans(100, "Bold")
d.text((M - 5, 112), "uplevel", font=f_title, fill=WHITE)

d.rectangle([M, 252, W - M, 253], fill=RULE)

f_body = sans(37, "Medium")
lines = [
    "Finds the engineering controls your repository does",
    "not have — then hands back a numbered plan.",
]
y = 296
for ln in lines:
    d.text((M, y), ln, font=f_body, fill=WHITE)
    y += 52

f_small = sans(29, "Regular")
d.text((M, y + 20), "It changes nothing until you pick.", font=f_small, fill=MUTED)

f_cmd = mono(27)
cmd = "claude plugin install uplevel@uplevel"
bbox = d.textbbox((0, 0), cmd, font=f_cmd)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
pad_x, pad_y = 26, 20
cx = M
cy = H - 74 - (th + 2 * pad_y)
d.rounded_rectangle([cx, cy, cx + tw + 2 * pad_x, cy + th + 2 * pad_y], radius=12, fill=PANEL)
d.text((cx + pad_x, cy + pad_y - bbox[1]), cmd, font=f_cmd, fill=ACCENT)

for ln in lines:
    w = d.textbbox((0, 0), ln, font=f_body)[2]
    assert M + w < W - M, "line overflows safe area: %r" % ln

img.save("assets/social-preview.png")
print("wrote assets/social-preview.png", img.size)
