"""True-scale replica of ZeD_BeltHUD (ZeD_Belt.lua, S125): layout constants, leather strap, ZeD boxes.
render(buckle_img, bw, bh, scale) -> RGBA image of the belt row with the buckle texture drawn in its box."""
from PIL import Image, ImageDraw
import os
# vanilla item icons for the slots (optional): run pz_unpack.py on media/texturepacks/UI2.pack into ref/icons
REF=os.path.join(os.path.dirname(os.path.abspath(__file__)),"ref","icons")
BOX,HAND=44,52; GAP,SIDE_GAP,PAD,END_GAP=7,14,12,10; STRAP_H=30
def hx(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
LT,LB,LE=hx("#5c4129"),hx("#3b2a1b"),hx("#1a1108"); ST=(214,178,117)
BOX_BG,BOX_LINE,COND=(174,171,158),(121,119,107),(42,85,17); BADGE=(110,100,12)
def render(buckle, bw, bh, s=2.0, items=("Item_Wrench","Item_Hammer_Forged",None,"Item_Pocketwatch"), bg=(28,30,24), resample=Image.NEAREST, frame=False):
    px=lambda v:int(round(v*s))
    n=len(items); k=(n+1)//2
    hand,box=px(HAND),px(BOX); h=hand
    # layout exactly as _layout
    x=0; boxes=[("hand","PRIMARY",0,0,hand,hand)]; x+=hand+px(END_GAP); strapX=x; x+=px(PAD); by=(h-box)//2
    for i in range(n):
        if i==k: x+=px(SIDE_GAP)+px(bw)+px(SIDE_GAP)-px(GAP)
        boxes.append(("slot",i,x,by,box,box)); x+=box+px(GAP)
    x-=px(GAP)
    buckleX=strapX+px(PAD)+k*box+(k-1)*px(GAP)+px(SIDE_GAP)
    x+=px(PAD); strapW=x-strapX; x+=px(END_GAP)
    boxes.append(("hand","SECONDARY",x,0,hand,hand)); x+=hand
    W=x+40; H=h+40; ox,oy=20,20
    im=Image.new("RGBA",(W,H),bg+(255,)); d=ImageDraw.Draw(im)
    sy=oy+(h-px(STRAP_H))//2; sh=px(STRAP_H); bands=6
    for i in range(bands):
        f=i/(bands-1); c=tuple(int(LT[j]+(LB[j]-LT[j])*f) for j in range(3))
        y0=sy+sh*i//bands; y1=sy+sh*(i+1)//bands; d.rectangle([ox+strapX,y0,ox+strapX+strapW-1,y1-1],fill=c)
    e=max(1,px(1)); d.rectangle([ox+strapX,sy,ox+strapX+strapW-1,sy+e-1],fill=LE); d.rectangle([ox+strapX,sy+sh-e,ox+strapX+strapW-1,sy+sh-1],fill=LE)
    for yy in (sy+px(4), sy+sh-px(5)):
        xx=ox+strapX+px(4)
        while xx<ox+strapX+strapW-px(4):
            ww=min(px(4),ox+strapX+strapW-px(4)-xx); 
            for t in range(e):
                for u in range(ww):
                    p=im.getpixel((xx+u,yy+t)); im.putpixel((xx+u,yy+t),tuple(int(p[j]*0.45+ST[j]*0.55) for j in range(3))+(255,))
            xx+=px(4)+px(3)
    for kind,lab,bx,byy,bw_,bh_ in boxes:
        d.rectangle([ox+bx,oy+byy,ox+bx+bw_-1,oy+byy+bh_-1],fill=BOX_BG,outline=BOX_LINE,width=e)
        if kind=="slot":
            it=items[lab]
            if it and os.path.exists(os.path.join(REF,it+".png")):
                ic=Image.open(os.path.join(REF,it+".png")); isz=px(34)
                ic=ic.resize((isz,isz),resample); im.alpha_composite(ic,(ox+bx+(bw_-isz)//2,oy+byy+(bh_-isz)//2-px(2)))
                d.rectangle([ox+bx+px(4),oy+byy+bh_-px(6),ox+bx+bw_-px(5),oy+byy+bh_-px(4)],fill=COND)
            bsz=px(12); d.rectangle([ox+bx,oy+byy,ox+bx+bsz,oy+byy+bsz],fill=BADGE)
    if buckle is not None:
        bxx=ox+buckleX; byy=oy+(h-px(bh))//2
        b=buckle.resize((px(bw),px(bh)),resample); im.alpha_composite(b,(bxx,byy))
        if frame: d.rectangle([bxx,byy,bxx+px(bw)-1,byy+px(bh)-1],outline=(255,0,255))
    return im
