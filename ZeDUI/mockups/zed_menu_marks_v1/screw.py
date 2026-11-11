from PIL import Image, ImageDraw, ImageFont
R='/home/claude/hermit-the-trog/zed.ui/42/media/textures/ZeD/wheel/'
PAPER=(0xf2,0xf2,0xf2); INK=(0x14,0x14,0x14)
def ink(n,s,rot=False):
    im=Image.open(R+'%d/zw_%s.png'%(s,n)).convert('RGBA')
    if rot: im=im.rotate(180)
    o=Image.new('RGB',im.size,PAPER); o.paste(Image.new('RGB',im.size,INK),(0,0),im); return o,im
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',12)
c=Image.new('RGB',(620,330),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(c)
cols=[('Screwdriver today','screwdriver',False),('Screwdriver, handle up','screwdriver',True),('Shovel','shovel',False)]
for i,(t,n,r) in enumerate(cols):
    x=18+i*200; d.text((x,12),t,fill=(0xe8,0xe4,0xdc),font=F)
    a,_=ink(n,16,r); b,_=ink(n,24,r)
    c.paste(a.resize((80,80),Image.NEAREST),(x,36)); c.paste(b.resize((96,96),Image.NEAREST),(x+90,36))
d.text((18,160),'True size on the menu paper, 16 and 24 at 1x and 2x',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,180,602,316],fill=PAPER)
for i,(t,n,r) in enumerate(cols):
    x=34+i*200; a,_=ink(n,16,r); b,_=ink(n,24,r)
    c.paste(a,(x,200)); c.paste(a.resize((32,32),Image.NEAREST),(x+24,192)); c.paste(b,(x+66,196)); c.paste(b.resize((48,48),Image.NEAREST),(x+96,186))
c.save('screwdriver_flip.png')
for s in (16,24): ink('screwdriver',s,True)[1].save('zw_screwdriver_%d.png'%s)
