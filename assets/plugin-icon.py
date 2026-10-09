# Regenerates plugin/.claude-plugin/icon.png, the square icon Anthropic's
# directory shows beside the listing. Run from the repository root:
#   python3 assets/plugin-icon.py
#
# Needs Pillow and nothing else: the mark is drawn, not set in a font, so it
# renders the same on any machine. The palette is the social preview's.
#
# The directory reads the icon once, the first time the plugin is saved or
# submitted in its developer portal. Changing this file afterwards does not
# change the listing.
from PIL import Image, ImageDraw

SIZE  = 1024
SCALE = 4                      # draw large, then downsample, for clean edges
BG     = (11, 14, 20)
LOW    = (34, 41, 53)
MID    = (62, 110, 74)
ACCENT = (126, 231, 135)

# Three chevrons stacked and pointing up, darkest at the bottom: each level
# above the last. Heavy strokes, so all three survive at 32 pixels.
HALF_WIDTH, RISE, THICKNESS = 300, 210, 120

s = SIZE * SCALE
img = Image.new("RGB", (s, s), BG)
d = ImageDraw.Draw(img)
cx = s // 2
w, rise, t = HALF_WIDTH * SCALE, RISE * SCALE, THICKNESS * SCALE
for apex, color in ((560, LOW), (360, MID), (160, ACCENT)):
    y = apex * SCALE
    d.polygon([(cx, y), (cx + w, y + rise), (cx + w, y + rise + t),
               (cx, y + t), (cx - w, y + rise + t), (cx - w, y + rise)], fill=color)

img = img.resize((SIZE, SIZE), Image.LANCZOS)
img.save("plugin/.claude-plugin/icon.png", optimize=True)
print("wrote plugin/.claude-plugin/icon.png", img.size)
