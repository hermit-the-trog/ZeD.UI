import sys, re
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
W='42/media/textures/ZeD/wheel/'
marks=dict(re.findall(r'\["(\w+)"\] = "(add|remove)"', open('42/media/lua/shared/ZeD/ContextPxIcons.lua').read()))
ADD=(0x44,0x91,0xE2); REM=(0xD9,0x57,0x2A)
def icon(id_, sz, ink):
    a=Image.open(W+'%d/zw_%s.png'%(sz,id_)).convert('RGBA').getchannel('A')
    out=Image.new('RGBA',(sz,sz),(0,0,0,0)); out.paste(Image.new('RGBA',(sz,sz),ink+(255,)),(0,0),a)
    if id_ in marks:
        m=Image.open(W+'%d/zw_%s_mk.png'%(sz,id_)).convert('RGBA').getchannel('A')
        out.paste(Image.new('RGBA',(sz,sz),(ADD if marks[id_]=='add' else REM)+(255,)),(0,0),m)
    return out
ARROW=["X..........","XX.........","XWX........","XWWX.......","XWWWX......","XWWWWX.....","XWWWWWX....","XWWWWWWX...","XWWWWWWWX..","XWWWWWWWWX.","XWWWWWXXXXX","XWWXWWX....","XWX.XWWX...","XX..XWWX...","X....XWWX..",".....XWWX..","......XX..."]
def arrow(d,x,y,k=2):
    for j,r in enumerate(ARROW):
        for i,ch in enumerate(r):
            if ch in 'XW': d.rectangle([x+i*k,y+j*k,x+i*k+k-1,y+j*k+k-1],fill=(0,0,0) if ch=='X' else (255,255,255))
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13); FB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',14)
SURF=(0x1c,0x1c,0x1c); TXT=(0xDA,0xDA,0xDA)
cases=[('Hovering a row in the loot list','double-click takes it','tray_in','Nails (x40)'),
       ('Dragging over the floor box','let go drops it','to_floor','Hammer'),
       ('Dragging over a crate in the list','let go puts it in','tray_out','Canned beans'),
       ("Dragging onto the doll's hand",'let go equips it','equip','Baseball bat')]
cw=300; img=Image.new('RGB',(20+cw*4,250),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(img)
d.text((20,12),'Idea (not built): a small icon rides beside the pointer when a click or a drop will act. Same icons and marks as the menus.',fill=(232,228,220),font=FB)
for n,(t,sub,ic,item) in enumerate(cases):
    x=20+n*cw; y=44
    d.text((x,y),t,fill=(232,228,220),font=FB); d.text((x,y+18),sub,fill=(190,186,178),font=F)
    px,py=x,y+46
    d.rectangle([px,py,px+cw-30,py+140],fill=SURF,outline=(0x33,0x33,0x33))
    for r,name in enumerate(['Plank', item, 'Rope', 'Duct tape']):
        ry=py+10+r*30
        if r==1: d.rectangle([px+6,ry-4,px+cw-36,ry+22],fill=(0x2c,0x3a,0x36))
        d.text((px+14,ry),name,fill=TXT,font=F)
    ax,ay=px+150,py+40
    arrow(d,ax,ay)
    ico=icon(ic,24,TXT); bx,by=ax+20,ay+26
    d.rectangle([bx-3,by-3,bx+27,by+27],fill=SURF,outline=(0x55,0x55,0x55))
    img.paste(ico,(bx,by),ico)
img.save(OUT); print('ok')
