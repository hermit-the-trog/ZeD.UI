from PIL import Image, ImageDraw, ImageFont
ADD=(0x0B,0x63,0xB0); REM=(0xC2,0x41,0x0C); INK=(0x14,0x14,0x14); PAPER=(0xf2,0xf2,0xf2)
def G(n): return [['.']*n for _ in range(n)]
def rect(g,x,y,w,h,v='#'):
    n=len(g)
    for yy in range(y,y+h):
        for xx in range(x,x+w):
            if 0<=xx<n and 0<=yy<n: g[yy][xx]=v
def boarded(n):
    g=G(n)
    if n==16:
        L,R,top,wl,wr,bot,t=1,14,1,3,12,14,1
    else:
        L,R,top,wl,wr,bot,t=1,22,1,4,19,22,2
    mid=(L+R)/2; rows=int((R-L+1)/2)
    for i in range(rows):
        x0=int(mid-0.5-i); x1=int(mid+0.5+i); rect(g,x0,top+i,x1-x0+1,1)
    rect(g,wr-(2 if n==16 else 4),top+(0 if n==16 else 1),2 if n==16 else 3,2 if n==16 else 4)   # the chimney
    y=top+rows; rect(g,wl,y,wr-wl+1,bot-y+1)                      # the walls
    if n==16:
        rect(g,5,y+1,6,5,'.'); rect(g,2,y+2,12,1); rect(g,2,y+4,12,1)
    else:
        rect(g,7,y+2,10,8,'.'); rect(g,2,y+3,20,2); rect(g,2,y+7,20,2)
    return g
def badge(g,kind):
    n=len(g); b=5 if n==16 else 7; t=1 if n==16 else 2; x0=n-b; y0=n-b; m=b//2
    rect(g,x0-1,y0-1,b+1,b+1,'.')
    rect(g,x0,y0+m-t//2,b,t,'m')
    if kind=='plus': rect(g,x0+m-t//2,y0,t,b,'m')
    return g
def img(g,S,mark=INK,ink=INK,paper=PAPER):
    n=len(g); im=Image.new('RGB',(n,n),paper)
    for y in range(n):
        for x in range(n):
            if g[y][x]=='#': im.putpixel((x,y),ink)
            elif g[y][x]=='m': im.putpixel((x,y),mark)
    return im.resize((n*S,n*S),Image.NEAREST)
def white(g):
    n=len(g); a=Image.new('RGBA',(n,n),(255,255,255,0)); m=Image.new('RGBA',(n,n),(255,255,255,0))
    for y in range(n):
        for x in range(n):
            if g[y][x] in '#m': a.putpixel((x,y),(255,255,255,255))
            if g[y][x]=='m': m.putpixel((x,y),(255,255,255,255))
    return a,m
sets=[('View safehouse',None,INK),('Claim',"plus",ADD),('Release',"minus",REM)]
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',12)
cv=Image.new('RGB',(18+3*290,330),(0x1c,0x1b,0x1a)); d=ImageDraw.Draw(cv)
out={}
for i,(t,k,col) in enumerate(sets):
    g16=boarded(16); g24=boarded(24)
    if k: badge(g16,k); badge(g24,k)
    out[t]=(g16,g24,col)
    x=18+i*290; d.text((x,12),t+'  16 / 24',fill=(0xe8,0xe4,0xdc),font=F)
    cv.paste(img(g16,7,col),(x,34)); cv.paste(img(g24,5,col),(x+124,34))
d.text((18,190),'True size on the menu paper (16 at 1x and 2x, 24 at 1x and 2x), and pointed',fill=(0xe8,0xe4,0xdc),font=F)
d.rectangle([18,210,cv.width-18,316],fill=PAPER)
x=34
for t,(g16,g24,col) in out.items():
    cv.paste(img(g16,1,col),(x,250)); cv.paste(img(g16,2,col),(x+24,242)); cv.paste(img(g24,1,col),(x+66,246)); cv.paste(img(g24,2,col),(x+98,230))
    cell=Image.new('RGB',(64,64),(0x2a,0x8c,0x8c)); cell.paste(img(g24,2,(255,255,255),(255,255,255),(0x2a,0x8c,0x8c)),(8,8)); cv.paste(cell,(x+160,228)); x+=290
cv.save('safehouse_A_v2.png')
names={'View safehouse':'safehouse','Claim':'safehouse_claim','Release':'safehouse_release'}
for t,(g16,g24,col) in out.items():
    for n,g in ((16,g16),(24,g24)):
        a,m=white(g); a.save('zw_%s_%d.png'%(names[t],n))
        if t!='View safehouse': m.save('zw_%s_%d_mk.png'%(names[t],n))
