exec(open('hands.py').read().split('def img(')[0])
from PIL import Image, ImageDraw, ImageFont
D35={'1':["010","110","010","010","111"],'2':["111","001","111","100","111"]}
D57={'1':["00100","01100","00100","00100","00100","00100","01110"],'2':["01110","10001","00001","00110","01000","10000","11111"]}
def cut(on,digit,s,x0,y0):
    g=(D35 if s==16 else D57)[digit]; on=set(on)
    for j,r in enumerate(g):
        for i,ch in enumerate(r):
            if ch=='1': on.discard((x0+i,y0+j))
    return on
def m16(s): return cut(main_hand(16),'1',16,8,8) if s==16 else cut(main_hand(24),'1',24,12,12)
def o16(s): return cut(off_hand(16),'2',16,5,8) if s==16 else cut(off_hand(24),'2',24,7,12)
def img(on,s,S,ink=INK,paper=PAPER):
    im=Image.new('RGB',(s,s),paper)
    for p in on: im.putpixel(p,ink)
    return im.resize((s*S,s*S),Image.NEAREST)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',12)
c=Image.new('RGB',(36+2*260,360),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(c)
for i,(t,f) in enumerate((('Primary, 1',m16),('Secondary, 2',o16))):
    x=18+i*260; d.text((x,12),t,fill=(0xe8,0xe4,0xdc),font=F)
    c.paste(img(f(16),16,5),(x,34)); c.paste(img(f(24),24,5),(x+90,34))
d.text((18,210),'True size on the menu paper, 16 and 24 at 1x and 2x; pointed',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,230,c.width-18,346],fill=PAPER)
for i,f in enumerate((m16,o16)):
    x=34+i*260
    c.paste(img(f(16),16,1),(x,262)); c.paste(img(f(16),16,2),(x+24,254)); c.paste(img(f(24),24,1),(x+66,258)); c.paste(img(f(24),24,2),(x+96,246))
    cell=Image.new('RGB',(64,64),(0x2a,0x8c,0x8c)); cell.paste(img(f(24),24,2,(255,255,255),(0x2a,0x8c,0x8c)),(8,8)); c.paste(cell,(x+150,244))
c.save('hands_digits_v1.png')
for s in (16,24):
    for y in range(s): print(''.join('#' if (x,y) in m16(s) else '.' for x in range(s)),'  ',''.join('#' if (x,y) in o16(s) else '.' for x in range(s)))
for n,f in (('hand_main',m16),('hand_off',o16)):
    for s in (16,24):
        o=Image.new('RGBA',(s,s),(255,255,255,0))
        for p in f(s): o.putpixel(p,(255,255,255,255))
        o.save('zw_%s_%d.png'%(n,s))
