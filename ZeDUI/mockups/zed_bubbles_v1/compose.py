from PIL import Image, ImageDraw, ImageFont
import bubbles as B
SRC = "/mnt/user-data/uploads/Zomboid/Screenshots/gallery_v3/story_11_smoke_break.png"
full = Image.open(SRC).convert("RGBA")
# take the old bar off: the same patch from one step up-left along the curb's slope
patch = full.crop((1852 + 152, 888 + 76, 1988 + 152, 948 + 76))
full.paste(patch, (1852, 888))
CX0, CY0, CW, CH = 1560, 640, 760, 560
HEAD = (1922, 948)
K = 2
def scene(kind, theme):
    im = full.crop((CX0, CY0, CX0 + CW, CY0 + CH))
    cv = B.Canvas(im, 0, 0, K)
    th = B.THEMES[theme]
    hx_, hy_ = (HEAD[0] - CX0) // K, (HEAD[1] - CY0) // K
    st = dict(L1="EATING", L2="CIGARETTE", R2="26%", frac=0.26, phase="work")
    if kind == "thought":
        B.thought(cv, st, hx_, hy_, th)
    elif kind == "speech":
        B.speech(cv, "Ahh. That's the stuff.", hx_, hy_, th, side=1)
    elif kind == "both":
        box_ = B.thought(cv, st, hx_, hy_, th)
        B.speech_side(cv, "Don't even think about it.", hx_, hy_, th, beside=box_)
    elif kind == "queue":
        B.thought(cv, dict(L1="RIPPING", R1="4/12", L2="SHEET", R2="40%", frac=(3 + 0.4) / 12, qn=12, phase="work"), hx_, hy_, th)
    elif kind == "done":
        B.thought(cv, dict(L1="DONE", L2="CIGARETTE", R2="100%", frac=1.0, phase="done"), hx_, hy_, th)
    return im
