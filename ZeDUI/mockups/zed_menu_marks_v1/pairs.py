from PIL import Image, ImageDraw, ImageFont
W='/home/claude/hermit-the-trog/zed.ui/42/media/textures/ZeD/wheel/16/'
SP='/tmp/claude-0/-home-claude/d71909eb-e188-5dfe-b817-1cb2ae9ba27f/scratchpad/'
PAPER=(0xf2,0xf2,0xf2); INK=(0x14,0x14,0x14); ADD=(0x0B,0x63,0xB0); REM=(0xC2,0x41,0x0C)
def load(p):
    im=Image.open(p).convert('RGBA'); return {(x,y) for y in range(16) for x in range(16) if im.getpixel((x,y))[3]>128}
def L(n):
    if n in ('sneak','sneak_off'): return load(SP+'sneak/zw_%s_16.png'%n)
    return load(W+'zw_'+n+'.png')
def img(on,col_px,S=3):
    im=Image.new('RGB',(16,16),PAPER)
    for p in on: im.putpixel(p,col_px.get(p,INK))
    return im.resize((48,48),Image.NEAREST)
strike=[('bulb_on','bulb_off','Light'),('alarm','alarm_off','Alarm'),('headlight_on','headlight_off','Headlights'),('key','key_off','Key'),
        ('eye','eye_off','Look'),('star','star_off','Favorite'),('craft','craft_off','Craft'),('magnifier','magnifier_off','Search'),
        ('sit_ground','sit_ground_off','Sit'),('autowalk','autowalk_off','Autowalk'),('sneak','sneak_off','Sneak')]
direc=[('car_enter','car_exit','Car door'),('window_open','window_close','Car window'),('zoom_in','zoom_out','Zoom'),('move_up','move_down','Move'),('box_up','box_down','Box')]
plusminus=[('plus','minus','Add / Remove')]
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',10); FB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',13)
def section(d,c,y,title,pairs,mode):
    d.text((18,y),title,fill=(0xe8,0xe4,0xdc),font=FB); y+=20
    cw=150; per=6
    for i,(a,b,lab) in enumerate(pairs):
        x=18+(i%per)*cw; yy=y+(i//per)*84
        A,B=L(a),L(b)
        tr=lambda p: p[0]>=10 and p[1]<=5
        br=lambda p: p[0]>=10 and p[1]>=10
        tl=lambda p: p[0]<=5 and p[1]<=5
        top=lambda p: p[1]<=5
        diag=lambda p: p[0]+p[1]==15
        ca={}; cb={}
        if mode=='whole': ca={p:ADD for p in A}; cb={p:REM for p in B}
        elif mode=='strike':
            if a in ('sit_ground','autowalk'): cb={p:REM for p in B if tr(p)}
            elif a=='sneak': cb={p:REM for p in B if tl(p)}
            else: cb={p:REM for p in B if diag(p)}
            if a=='autowalk': ca={p:ADD for p in A if tr(p)}
        else:
            reg={'car_enter':br,'window_open':br,'box_up':top,'zoom_in':(lambda p: 4<=p[0]<=8 and 3<=p[1]<=7),'move_up':(lambda p: True)}[a]
            ca={p:ADD for p in A if reg(p)}; cb={p:REM for p in B if reg(p)}
        d.rectangle([x,yy,x+cw-8,yy+76],fill=PAPER)
        c.paste(img(A,ca),(x+12,yy+6)); c.paste(img(B,cb),(x+78,yy+6))
        tw=d.textlength(lab,font=F); d.text((x+(cw-8)/2-tw/2,yy+60),lab,fill=INK,font=F)
    return y+((len(pairs)+per-1)//per)*84+10
c=Image.new('RGB',(18*2+150*6,620),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(c); y=14
y=section(d,c,y,'1. Add and remove: the plain plus and minus, whole glyph',plusminus,'whole')
y=section(d,c,y,'2. On and off: the off twin\'s strike or x takes red; the on stays ink',strike,'strike')
y=section(d,c,y,'3. Either way: whatever differs between the two, blue for the first, red for the second',direc,'dir')
c.crop((0,0,c.width,y)).save('pairs_v1.png'); print(y)
