from PIL import Image, ImageDraw, ImageFont
W='/home/claude/hermit-the-trog/zed.ui/42/media/textures/ZeD/wheel/16/'
PAPER=(0xf2,0xf2,0xf2); INK=(0x14,0x14,0x14)
def hx(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))
ADD=hx('#0B63B0'); REM=hx('#C2410C')
mk={'br':lambda x,y: x>=10 and y>=10,'tr':lambda x,y: x>=11 and y<=4,'drop':lambda x,y: y<=10,
    'tray':lambda x,y: 4<=x<=11 and y<=10,'mag':lambda x,y: 5<=x<=9 and 8<=y<=13,'lid':lambda x,y: y<=3}
add=[('equip','Equip','br'),('tray_out','Take','tray'),('mag_in','Load','mag'),('rounds_in','Load rounds','mag'),('battery_in','Battery in','br'),('fill','Fill','tr')]
rem=[('unequip','Unequip','br'),('tray_in','Put in','tray'),('to_floor','Drop','drop'),('mag_out','Unload','mag'),('rounds_out','Unload rounds','mag'),
     ('battery_out','Battery out','br'),('empty','Empty','tr'),('bandage_off','Remove bandage','br'),('unplug','Unplug','br'),('bulb_remove','Remove light','br'),
     ('shield_minus','Release safehouse','br'),('trash','Dispose','lid')]
def icon(n,mask,col,S):
    im=Image.open(W+'zw_'+n+'.png').convert('RGBA'); out=Image.new('RGBA',(16,16),(0,0,0,0))
    for y in range(16):
        for x in range(16):
            if im.getpixel((x,y))[3]>128: out.putpixel((x,y),(col if mk[mask](x,y) else INK)+(255,))
    return out.resize((16*S,16*S),Image.NEAREST)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',10); FB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',13)
S=3; colw=82; per=6; Wd=18*2+colw*per
rows=[('Blue #0B63B0: it ends up with you, or something is added',add,ADD)]+[('Red #C2410C: it leaves you, or something is taken away',rem[:6],REM),('',rem[6:],REM)]
img=Image.new('RGB',(Wd,600),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(img); y=18
for t,items,col in rows:
    if t: d.text((18,y),t,fill=(0xe8,0xe4,0xdc),font=FB); y+=20
    d.rectangle([18,y,Wd-18,y+16*S+28],fill=PAPER)
    for i,(n,lab,m) in enumerate(items):
        x=18+i*colw+(colw-16*S)//2; ic=icon(n,m,col,S); img.paste(ic,(x,y+5),ic)
        tw=d.textlength(lab,font=F); d.text((18+i*colw+colw/2-tw/2,y+16*S+11),lab,fill=INK,font=F)
    y+=16*S+36
for line in ['Ink, unchanged: arrows that say where or which way (main or off hand, belt left or right,','holster, car door, car window, tent down), and the x, check and strike marks.','Pointed rows: the whole icon in the accent\'s text color, marks included.']:
    d.text((18,y),line,fill=(0xe8,0xe4,0xdc),font=F); y+=14
y+=6
img.crop((0,0,Wd,y)).save('ctx_marks_final.png')
