from PIL import Image, ImageDraw, ImageFont
R='/home/claude/hermit-the-trog/zed.ui/42/media/textures/ZeD/wheel/'
PAPER=(0xf2,0xf2,0xf2); INK=(0x14,0x14,0x14)
def load(n,s):
    im=Image.open(R+'%d/zw_%s.png'%(s,n)).convert('RGBA'); return {(x,y) for y in range(s) for x in range(s) if im.getpixel((x,y))[3]>128}
ARROW={16:["..#.",
           "..##",
           "####",
           "..##",
           "..#."], 
       24:["....#..",
           "....##.",
           "#######",
           "#######",
           "....##.",
           "....#.."]}
def main_hand(s):
    """the open hand, palm out, thumb low at the left (toward the body); moved right to make room; an arrow above the
    thumb pointing into the hand"""
    dx,ay=(2,2) if s==16 else (4,2)
    on={(x+dx,y) for (x,y) in load('hand',s) if x+dx<s}
    for j,r in enumerate(ARROW[s]):
        for i,ch in enumerate(r):
            if ch=='#': on.add((i,ay+j))
    return on
def off_hand(s): return {(s-1-x,y) for (x,y) in main_hand(s)}
def img(on,s,S,ink=INK,paper=PAPER):
    im=Image.new('RGB',(s,s),paper)
    for p in on: im.putpixel(p,ink)
    return im.resize((s*S,s*S),Image.NEAREST)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',12)
c=Image.new("RGB",(36+4*175,360),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(c)
cols=[('Primary today',load('hand_main',16),load('hand_main',24)),('Secondary today',load('hand_off',16),load('hand_off',24)),
      ('Primary, new',main_hand(16),main_hand(24)),('Secondary, new',off_hand(16),off_hand(24))]
for i,(t,a,b) in enumerate(cols):
    x=18+i*170; d.text((x,12),t,fill=(0xe8,0xe4,0xdc),font=F)
    c.paste(img(a,16,4),(x,34)); c.paste(img(b,24,4),(x,104))
d.text((18,210),'True size on the menu paper, 16 and 24 at 1x and 2x, as they sit next to each other in the menu',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,230,c.width-18,346],fill=PAPER)
for i,(t,a,b) in enumerate(cols):
    x=34+i*175
    c.paste(img(a,16,1),(x,250)); c.paste(img(a,16,2),(x+24,242)); c.paste(img(b,24,1),(x+66,246)); c.paste(img(b,24,2),(x+96,236))
c.save('hands_v1.png')
for n,f in (('hand_main',main_hand),('hand_off',off_hand)):
    for s in (16,24):
        o=Image.new('RGBA',(s,s),(255,255,255,0))
        for p in f(s): o.putpixel(p,(255,255,255,255))
        o.save('zw_%s_%d.png'%(n,s))
for s in (16,24):
    print(s); [print(''.join('#' if (x,y) in main_hand(s) else '.' for x in range(s))) for y in range(s)]
