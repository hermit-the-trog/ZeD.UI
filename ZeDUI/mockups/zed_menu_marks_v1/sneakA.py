import sys, math
sys.path.insert(0,'/home/claude/hermit-the-trog/zed.ui/ZeDUI/tools/wheelpx')
from doll import Px
from PIL import Image, ImageDraw, ImageFont
A16=["................","................","................","................",
   "..........###...",".........#####..",".........#####..",".........#####..",
   "....####..###...","...#######...##.","...########.##..","....#####.......",
   "....##..##......","...##....#......","...#.....#......","..#......##....."]
def grid_px(rows,dx=0):
    c=Px(16)
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch=='#': c.put(x+dx,y)
    return c
A24=["........................","........................","........................","........................",
     "........................",
     "........................",
     "...............###......",
     "..............#####.....",
     ".............#######....",
     ".............#######....",
     ".............#######....",
     "..............#####.....",
     "......######...###......",
     ".....##########.....##..",
     "....###########...###...",
     "....##############......",
     ".....#########..........",
     "......########..........",
     "......###...###.........",
     ".....####...###.........",
     "....####.....##.........",
     "....##.......##.........",
     "...###.......###........",
     "...##........####......."]
def a24():
    """the 24 drawn from the approved 16 at one and a half times, the head the doll's 7 disc"""
    c=Px(24)
    for y,r in enumerate(A24):
        for x,ch in enumerate(r):
            if ch=='#': c.put(x,y)
    return c
def badge_x(c,n):
    b=5 if n==16 else 7; x0=0; y0=0
    c.rect(x0,y0,b+1,b+1,False)
    t=1 if n==16 else 2
    for i in range(b):
        c.put(x0+i,y0+i); c.put(x0+b-1-i,y0+i)
        if t>1 and i<b-1: c.put(x0+i+1,y0+i); c.put(x0+b-2-i,y0+i)
    return c
def shifted(c,dx):
    o=Px(c.w)
    for x,y in c.on: o.put(x+dx,y)
    return o
s16=grid_px(A16); s24=a24()
off16=badge_x(shifted(s16,0),16); off24=badge_x(shifted(s24,0),24)
def img(c,S,ink=(0x14,0x14,0x14),paper=(0xf2,0xf2,0xf2)):
    im=Image.new('RGB',(c.w,c.h),paper)
    for p in c.on: im.putpixel(p,ink)
    return im.resize((c.w*S,c.h*S),Image.NEAREST)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',12)
cv=Image.new('RGB',(700,330),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(cv)
for i,(t,c,S) in enumerate([('Sneak 16',s16,8),('Sneak 24',s24,6),('Stop sneaking 16',off16,8),('Stop sneaking 24',off24,6)]):
    x=18+i*170; d.text((x,12),t,fill=(0xe8,0xe4,0xdc),font=F); cv.paste(img(c,S),(x,34))
d.text((18,220),'True size on the menu paper: 16 at 1x and 2x, 24 at 1x and 2x; pointed on the accent',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,240,682,316],fill=(0xf2,0xf2,0xf2))
x=34
for c16,c24 in ((s16,s24),(off16,off24)):
    cv.paste(img(c16,1),(x,270)); cv.paste(img(c16,2),(x+24,262)); cv.paste(img(c24,1),(x+66,266)); cv.paste(img(c24,2),(x+100,254)); x+=180
cell=Image.new('RGB',(64,64),(0x2a,0x8c,0x8c)); cell.paste(img(s24,2,ink=(255,255,255),paper=(0x2a,0x8c,0x8c)),(8,8)); cv.paste(cell,(x+20,246))
cv.save('sneak_A_v2.png')
for name,c in (('zw_sneak_16',s16),('zw_sneak_24',s24),('zw_sneak_off_16',off16),('zw_sneak_off_24',off24)): c.image().save(name+'.png')
