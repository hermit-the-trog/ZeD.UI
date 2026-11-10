from PIL import Image, ImageDraw, ImageFont
def f16():
    on=set(); dx=-2
    head=["......###.......",".....#####......",".....#####......",".....#####......","......###......."]
    for y,r in enumerate(head):
        for x,ch in enumerate(r):
            if ch=='#': on.add((x+dx,y))
    for y in range(6,11):
        for x in range(5+dx,10+dx): on.add((x,y))
    for y in range(11,16):
        for x in (5+dx,6+dx,8+dx,9+dx): on.add((x,y))
    on.update({(1,6),(1,7),(0,8),(0,9)})            # the free arm hangs, as the doll's stand
    for y in range(0,3):                              # three tines
        for x in (10,12,14): on.add((x,y))
    for x in range(10,15): on.add((x,3))              # the bar
    on.update({(11,4),(13,4)})                        # the neck, so it reads fork, not trident
    for y in range(4,11): on.add((12,y))              # the handle
    for x in (9,10,11): on.add((x,7))                 # the arm out to the handle
    return on
def f24():
    on=set()
    cx,cy,r=7.5,3.5,3.5
    for y in range(7):
        for x in range(4,11):
            if (x+.5-cx)**2+(y+.5-cy)**2<=r*r-0.5+0.01: on.add((x,y))
    for y in range(8,16):
        for x in range(4,11): on.add((x,y))
    for y in range(16,24):
        for x in (4,5,6,8,9,10): on.add((x,y))
    for y in range(8,16):                             # the free arm hangs, 2 px, one column clear
        for x in (1,2): on.add((x,y))
    for y in range(0,6):                              # three 2 px tines
        for x in (13,14,16,17,19,20): on.add((x,y))
    for y in (6,7):
        for x in range(13,21): on.add((x,y))          # the bar
    for x in range(14,20): on.add((x,8))              # the neck
    for y in range(9,17):
        for x in (16,17): on.add((x,y))               # the handle
    for y in (11,12):
        for x in (12,13,14,15): on.add((x,y))         # the arm out to the handle
    return on
def img(on,n,S,ink=(0x14,0x14,0x14),paper=(0xf2,0xf2,0xf2)):
    im=Image.new('RGB',(n,n),paper)
    for p in on:
        if 0<=p[0]<n and 0<=p[1]<n: im.putpixel(p,ink)
    return im.resize((n*S,n*S),Image.NEAREST)
def white(on,n):
    im=Image.new('RGBA',(n,n),(255,255,255,0))
    for p in on: im.putpixel(p,(255,255,255,255))
    return im
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',13)
c=Image.new('RGB',(560,300),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(c)
d.text((18,14),'16 (at rest)',fill=(0xe8,0xe4,0xdc),font=F); c.paste(img(f16(),16,8),(18,36))
d.text((180,14),'24 (pointed)',fill=(0xe8,0xe4,0xdc),font=F); c.paste(img(f24(),24,6),(180,36))
d.text((18,200),'True size on the menu paper: 16 at 1x and 2x, 24 at 1x and 2x',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,222,542,286],fill=(0xf2,0xf2,0xf2))
c.paste(img(f16(),16,1),(34,246)); c.paste(img(f16(),16,2),(64,238)); c.paste(img(f24(),24,1),(120,242)); c.paste(img(f24(),24,2),(160,230))
# the pointed state: whole icon in text-on-accent on the accent cell (PZ Teal shown)
d.text((360,14),'Pointed',fill=(0xe8,0xe4,0xdc),font=F)
cell=Image.new('RGB',(24*4+16,24*4+16),(0x2a,0x8c,0x8c)); w=img(f24(),24,4,ink=(255,255,255),paper=(0x2a,0x8c,0x8c)); cell.paste(w,(8,8)); c.paste(cell,(360,36))
c.save('eat_fork_v2.png'); white(f16(),16).save('zw_eat_16.png'); white(f24(),24).save('zw_eat_24.png')
